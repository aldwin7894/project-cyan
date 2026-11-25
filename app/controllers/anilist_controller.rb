# frozen_string_literal: true
# typed: true

require "sorbet-runtime"

class AnilistController < ApplicationController
  include FormatDateHelper

  def index
    # index
  end

  def show
    @user = AnilistUser.find_by(job_id: params[:id])
    if @user.blank?
      raise ActionController::RoutingError.new("Follow list not found")
    end

    @following = @user.following.order(username: :asc).pluck(:username) || []
    @followers = @user.followers.order(username: :asc).pluck(:username) || []
    @following_count = @following.size
    @followers_count = @followers.size
  end

  def new
    # new
  end


  def fetch_followers
    @success = false
    username = T.let(params[:username], String).strip
    turnstile_token = T.let(params["cf-turnstile-response"], String)

    return @error = "Username can't be empty" if username.blank?
    return @error = "CAPTCHA wasn't completed, please try again" if turnstile_token.blank?

    captcha_valid = verify_turnstile
    unless captcha_valid
      @error = "You're probably a bot, aren't you?"
      return render layout: false
    end

    cooldown = Rails.cache.fetch("ANILIST/FOLLOW_CHECKER_CD/#{remote_ip}")
    if Time.zone.now.to_i <= cooldown.to_i && !Rails.env.development?
      cd_mins = cooldown - Time.zone.now
      return @error = "On cooldown, please try again after #{format_date(cd_mins, true, false)}."
    end

    @user = AnilistUser
              .where(username: username)
              .collation(locale: "en", strength: 2)
              .first

    if @user.blank?
      # If the user is not found in the database, fetch their ID from AniList
      user_id = query(AniList::UserIdQuery, username:).user.id

      # If the user is found in the database, update their username if it has changed
      @user = AnilistUser.find(_id: user_id)
      if @user.present?
        @user.username = username
      # If the user is not found in the database, create a new AnilistUser record with the fetched ID and username
      else
        @user = AnilistUser.new(
          _id: user_id,
          username:
        )
      end
    end

    if @user.sync_in_progress?
      @user.save
      return @error = "User <strong>#{username}</strong> is already in the queue and is being processed!<br />Please wait for the result."
    end

    @user.sync_in_progress = true
    @user.last_known_error = nil
    @user.remote_ip = remote_ip
    @job_id = AnilistFollowListCheckerJob.perform_async(@user._id, Time.current.iso8601)
    @user.job_id = @job_id
    @user.save

    Rails.cache.fetch("ANILIST/FOLLOW_CHECKER_CD/#{remote_ip}", expires_in: 20.minutes) do
      20.minutes.from_now
    end
    @success = true
  rescue Graphlient::Errors::ServerError => error
    logger.tagged("ANILIST", "fetch_followers") do
      logger.error(error.inner_exception)
    end

    case error.status_code
    when 429
      Rails.cache.write("ANILIST/FOLLOW_CHECKER_CD/#{remote_ip}", expires_in: 5.minutes)
      @error = "We're being rate-limited by AniList API, please try again later."
    when 404
      Rails.cache.write("ANILIST/FOLLOW_CHECKER_CD/#{remote_ip}", nil)
      @error = "User <strong>#{username}</strong> was not found or has a private profile."
    else
      @error = "Something went wrong, please try again later."
    end
  rescue StandardError => error
    logger.tagged("ANILIST", "fetch_followers") do
      logger.error(error)
    end
    @error = "Something went wrong, please try again later."
  end
end
