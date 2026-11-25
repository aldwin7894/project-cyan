# frozen_string_literal: true
# typed: true

require "ani_list"

class AnilistFollowListCheckerJob
  include Sidekiq::Job
  sidekiq_options retry: 3,
    queue: "default",
    lock: :until_and_while_executing,
    lock_args_method: ->(args) { [args.first, args.second] },
    on_conflict: {
      client: :log,
      server: :reject
    }
  sidekiq_retry_in do |count|
    5.minutes * (count + 1)
  end
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

  def perform(id, sync_time, page = 1, fetch_followers = true, fetch_following = true)
    user = AnilistUser.find(id)
    username = "[#{user.username}] ".blue

    logger.info(TAG + username + "FETCHING FOLLOW LIST: PAGE #{page}".green)
    response = AniList::Client.execute(AniList::UserFollowListQuery, user_id: user._id, page:, fetch_followers:, fetch_following:)

    followers_page = response&.data&.followers_page
    following_page = response&.data&.following_page

    follower_ops = (followers_page&.followers || []).map do |f|
      {
        update_one: {
          filter: { anilist_user_id: user.id, username: f.name },
          update: {
            "$set" => { updated_at: sync_time },
            "$setOnInsert" => { created_at: sync_time }
          },
          upsert: true
        }
      }
    end
    following_ops = (following_page&.following || []).map(&:name).map do |username|
      {
        update_one: {
          filter: { anilist_user_id: user.id, username: username },
          update: {
            "$set" => { updated_at: sync_time },
            "$setOnInsert" => { created_at: sync_time }
          },
          upsert: true
        }
      }
    end


    AnilistUserFollower.collection.bulk_write(follower_ops, ordered: false) if follower_ops.any?
    AnilistUserFollowing.collection.bulk_write(following_ops, ordered: false) if following_ops.any?

    fetch_followers = followers_page&.page_info&.has_next_page? ? true : false
    fetch_following = following_page&.page_info&.has_next_page? ? true : false
    page += 1

    if fetch_followers || fetch_following
      self.class.perform_in(5.seconds, id, sync_time, page, fetch_followers, fetch_following)
    else
      AnilistUserFollower.where(anilist_user_id: user.id, "updated_at.lt": sync_time).delete_all
      AnilistUserFollowing.where(anilist_user_id: user.id, "updated_at.lt": sync_time).delete_all

      logger.info(TAG + username + "FETCHING DONE".green)
      user.last_known_error = nil
      user.sync_in_progress = false
    end
  rescue Graphlient::Errors::ServerError, Graphlient::Errors::FaradayServerError => error
    case error.status_code
    when 404
      logger.info(TAG + username + "NOT FOUND OR HAS A PRIVATE PROFILE".red)
      user.sync_in_progress = false
    when 429
      logger.error(TAG + username + "RATE LIMITED, WILL BE RETRIED".red)
      throw error
    when 400
      logger.error(TAG + username + "BAD REQUEST, WILL NOT BE RETRIED: #{error.response}".red)
      user.last_known_error = "#{error.status_code} - #{error.inner_exception} - #{error.response}"
      user.sync_in_progress = false
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
