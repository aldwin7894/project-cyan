# typed: false

require "anilist"

class AnilistFollowListCheckerJob
  include Sidekiq::Job
  sidekiq_options retry: 5,
    lock: :until_and_while_executing,
    on_conflict: { client: :log, server: :reject }
  sidekiq_retry_in { 1.minute }
  sidekiq_retries_exhausted do |job, error|
    user = AnilistUser.find_by(job["args"].first)
    user.last_known_error = error.message
    user.sync_in_progress = false
    user.save
  end

  def perform(id, type = "following", page = 1)
    user = AnilistUser.find(id)
    if type === "following" && page === 1
      user.following = []
      user.job_id = self.jid
    end
    user.followers = [] if type === "followers" && page === 1

    if type === "following"
      following = user.following
      response = AniList::Client.execute(AniList::UserFollowingQuery, user_id: user._id, page:)
      following.push(*response.data.page.following.map(&:name))
      following.sort!

      user.following = following
    elsif type === "followers"
      followers = user.followers
      response = AniList::Client.execute(AniList::UserFollowersQuery, user_id: user._id, page:)
      followers.push(*response.data.page.followers.map(&:name))
      followers.sort!

      user.followers = followers
    end

    if response.data.page.page_info.has_next_page? === false && type === "following"
      self.class.perform_in(20.seconds, id, "followers", 1)
    elsif response.data.page.page_info.has_next_page?
      self.class.perform_in(20.seconds, id, type, page + 1)
    else
      user.sync_in_progress = false
    end
  rescue Graphlient::Errors::ServerError => error
    user.last_known_error = error.message

    case error.status_code
    when 404
      logger.info("[ANILIST FOLLOW CHECKER] ".yellow + "#{@user.username} was not found or has a private profile.".red)
      user.sync_in_progress = false
    when 429
      logger.error("[ANILIST FOLLOW CHECKER] ".yellow + "Rate limited".red)
      throw error
    else
      logger.error("[ANILIST FOLLOW CHECKER] ".yellow + error.message.red)
      throw error
    end
  rescue StandardError => error
    user.last_known_error = error.message
    user.sync_in_progress = false
  ensure
    user.save
  end
end