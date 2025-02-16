# frozen_string_literal: true
# typed: true

require "anilist"

class AnilistFollowListCheckerJob
  include Sidekiq::Job
  sidekiq_options retry: 5,
    queue: 'default',
    lock: :until_and_while_executing,
    lock_args_method: ->(args) { [args.first] },
    on_conflict: {
      client: :log,
      server: :reject
    }
  sidekiq_retries_exhausted do |job, error|
    user = AnilistUser.find_by(job["args"].first)
    user.last_known_error = error.message
    user.sync_in_progress = false
    user.save
  end

  TAG = "[ANILIST FOLLOW CHECKER] ".yellow

  def perform(id, type = "following", page = 1)
    user = AnilistUser.find(id)
    username = "[#{user.username}] ".blue
    if type === "following" && page === 1
      user.following = []
      user.job_id = self.jid
    end
    user.followers = [] if type === "followers" && page === 1

    if type === "following"
      logger.info(TAG + username + "FETCHING FOLLOWING: PAGE #{page}".green)
      following = user.following
      response = AniList::Client.execute(AniList::UserFollowingQuery, user_id: user._id, page:)
      following.push(*response.data.page.following.map(&:name))
      following.sort!

      user.following = following
    elsif type === "followers"
      logger.info(TAG + username + "FETCHING FOLLOWERS: PAGE #{page}".green)
      followers = user.followers
      response = AniList::Client.execute(AniList::UserFollowersQuery, user_id: user._id, page:)
      followers.push(*response.data.page.followers.map(&:name))
      followers.sort!

      user.followers = followers
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
    user.last_known_error = error.message

    case error.status_code
    when 404
      logger.info(TAG + username + "NOT FOUND OR HAS A PRIVATE PROFILE".red)
      user.sync_in_progress = false
    when 429
      logger.error(TAG + username + "RATE LIMITED, WILL BE RETRIED".red)
      throw error
    else
      logger.error(TAG + username + error.message.red)
      throw error
    end
  rescue StandardError => error
    user.last_known_error = error.message
    user.sync_in_progress = false
  ensure
    user.save
  end
end
