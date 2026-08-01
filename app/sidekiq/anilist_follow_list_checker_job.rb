# frozen_string_literal: true
# typed: true

require "anilist"

class AnilistFollowListCheckerJob
  include Sidekiq::Job
  sidekiq_options retry: 10,
    queue: "default",
    lock: :until_and_while_executing,
    lock_args_method: ->(args) { [args.first] },
    on_conflict: {
      client: :log,
      server: :reject
    }
  sidekiq_retries_exhausted do |job, error|
    user = AnilistUser.find(job["args"].first)

    case error
    when Graphlient::Errors::ServerError
      last_known_error = "#{error.status_code} - #{error.inner_exception} - #{error.response}"
    else
      last_known_error = "#{error.class} - #{error.message} - #{error.backtrace.join("\n")}"
    end

    user.last_known_error = last_known_error
    user.sync_in_progress = false
    user.save

    if user.remote_ip.present?
      Rails.cache.write("ANILIST/FOLLOW_CHECKER_CD/#{user.remote_ip}", nil)
    end
  end

  TAG = "[ANILIST FOLLOW CHECKER] ".yellow

  def perform(id, type = "following", page = 1)
    user = AnilistUser.find(id)
    username = "[#{user.username}] ".blue
    if type === "following" && page === 1
      user.following.destroy_all
      user.followers.destroy_all
    end

    if type === "following"
      logger.info(TAG + username + "FETCHING FOLLOWING: PAGE #{page}".green)
      response = AniList::Client.execute(AniList::UserFollowingQuery, user_id: user._id, page:)
      following = response.data.page.following.map(&:name)

      following.each do |username|
        AnilistUserFollowing.create!(anilist_user: user, username:)
      end
    elsif type === "followers"
      logger.info(TAG + username + "FETCHING FOLLOWERS: PAGE #{page}".green)
      response = AniList::Client.execute(AniList::UserFollowersQuery, user_id: user._id, page:)
      followers = response.data.page.followers.map(&:name)

      followers.each do |username|
        AnilistUserFollower.create!(anilist_user: user, username:)
      end
    end

    if response.data.page.page_info.has_next_page? === false && type === "following"
      self.class.perform_in(5.seconds, id, "followers", 1)
    elsif response.data.page.page_info.has_next_page?
      self.class.perform_in(5.seconds, id, type, page + 1)
    else
      logger.info(TAG + username + "FETCHING DONE".green)
      user.sync_in_progress = false
    end
  rescue Graphlient::Errors::ServerError => error
    case error.status_code
    when 404
      logger.info(TAG + username + "NOT FOUND OR HAS A PRIVATE PROFILE".red)
      user.sync_in_progress = false
    when 429
      logger.error(TAG + username + "RATE LIMITED, WILL BE RETRIED".red)
      throw error
    else
      logger.error(TAG + username + "AN UNEXPECTED ERROR OCCURRED: #{error.status_code} - #{error.inner_exception} - #{error.response}".red)
      throw error
    end
  rescue StandardError => error
    logger.error(TAG + username + "AN UNEXPECTED ERROR OCCURRED: #{error.message} - #{error.backtrace&.join("\n")}".red)
    throw error
  ensure
    user.save
  end
end
