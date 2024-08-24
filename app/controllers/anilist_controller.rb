# frozen_string_literal: true
# typed: true

class AnilistController < ApplicationController
  include FormatDateHelper
  before_action :check_if_from_cloudfront

  def index
    # index
  end

  def show
    @user = AnilistUser.find_by(job_id: params[:id])
    if @user.blank?
      raise ActionController::RoutingError.new("Not Found")

    end

    @following = @user.following
    @followers = @user.followers
    @following_count = @following.size
    @followers_count = @followers.size
  end
  def new
    # new
  end


  def fetch_followers
    @success = false
    username = T.let(params[:username], String).strip
    return @error = "Username can't be empty" if username.blank?

    captcha_valid = verify_recaptcha action: "captcha", minimum_score: 0.5
    unless captcha_valid || Rails.env.development?
      @error = "You're probably a bot, aren't you?"
      return render layout: false
    end

    cooldown = Rails.cache.fetch("ANILIST/FOLLOW_CHECKER_CD")
    if Time.zone.now.to_i <= cooldown.to_i && !Rails.env.development?
      cd_mins = cooldown - Time.zone.now
      return @error = "On cooldown, please try again after #{format_date(cd_mins, true, false)}."
    end

    @user = AnilistUser.find_by(username:)
    if @user.present? && @user.sync_in_progress?
      return @error = "User <strong>#{username}</strong> is already in the queue and is being processed!<br />Please wait for the result."
    end

    if @user.blank?
      user_id = query(AniList::UserIdQuery, username:).user.id
      @user = AnilistUser.new(
        _id: user_id,
        username:,
      )
    end

    @user.sync_in_progress = true
    @user.last_known_error = nil
    @user.save
    @job_id = AnilistFollowListCheckerJob.perform_async(@user._id)

    Rails.cache.fetch("ANILIST/FOLLOW_CHECKER_CD", expires_in: 30.minutes) do
      30.minutes.from_now
    end
    @success = true
  rescue Graphlient::Errors::ServerError => error
    logger.tagged("ANILIST", "fetch_followers") do
      logger.error(error.inner_exception)
    end

    case error.status_code
    when 429
      Rails.cache.write("ANILIST_FOLLOW_CHECKER_CD", expires_in: 5.minutes)
      @error = "We're being rate-limited by AniList API, please try again later."
    when 404
      Rails.cache.write("ANILIST_FOLLOW_CHECKER_CD", nil)
      @error = "User <strong>#{username}</strong> was not found or has a private profile."
    else
      @error = "Something went wrong, please try again later."
    end
  end
end
