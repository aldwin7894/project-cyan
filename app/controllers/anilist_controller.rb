# frozen_string_literal: true
# typed: true

class AnilistController < ApplicationController
  include FormatDateHelper
  before_action :check_if_from_cloudfront

  def index
    # index
  end

  def new
    # new
  end

  def fetch_followers
    @success = false
    return @error = "Username can't be empty" if params[:username].blank?

    id = Rails.cache.fetch("ANILIST/#{params[:username]}/USER_ID", expires_in: 1.year, skip_nil: true) do
      query(AniList::UserIdQuery, username: params[:username]).user.id
    end

    captcha_valid = verify_recaptcha action: "captcha", minimum_score: 0.5
    unless captcha_valid || Rails.env.development?
      @error = "You're probably a bot, aren't you?"
      return render layout: false
    end

    @following_count = 0
    @followers_count = 0
    @following = []
    @followers = []

    cooldown = Rails.cache.fetch("ANILIST/FOLLOW_CHECKER_CD")
    if Time.zone.now.to_i <= cooldown.to_i && !Rails.env.development?
      cd_mins = cooldown - Time.zone.now
      return @error = "On cooldown, please try again after #{format_date(cd_mins, true, false)}."
    end

    # CHECK FIRST IF FOLLOW LIST CAN BE HANDLED
    @following_page = 1
    @followers_page = 1

    data = query(AniList::UserFollowingQuery, user_id: id, page: @following_page)
    @following_count = data.page.page_info.total
    @following.push(*data.page.following.map(&:name))

    sleep 0.7 unless Rails.env.development?

    data = query(AniList::UserFollowersQuery, user_id: id, page: @followers_page)
    @followers_count = data.page.page_info.total
    @followers.push(*data.page.followers.map(&:name))

    limit = ENV.fetch("ANILIST_FOLLOW_LIST_LIMIT", 600).to_i
    if @following_count > limit || @followers_count > limit
      return @error = "Your follow list is too large to be handled.<br />AniList is currently imposing a tight limit on its API requests, this might change in the future."
    end

    @followers_page += 1
    loop do
      sleep 0.7 unless Rails.env.development?
      data = query(AniList::UserFollowingQuery, user_id: id, page: @following_page)
      @following.push(*data.page.following.map(&:name))

      if data.page.page_info.has_next_page? == false
        break
      else
        @following_page += 1
      end
    end

    @following_page += 1
    loop do
      sleep 0.7 unless Rails.env.development?
      data = query(AniList::UserFollowersQuery, user_id: id, page: @followers_page)
      @followers.push(*data.page.followers.map(&:name))

      if data.page.page_info.has_next_page? == false
        break
      else
        @followers_page += 1
      end
    end

    Rails.cache.fetch("ANILIST/FOLLOW_CHECKER_CD", expires_in: 2.minutes) do
      2.minutes.from_now
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
      @error = "#{params[:username]} was not found or has a private profile."
    else
      @error = "Something went wrong, please try again later."
    end
  end
end
