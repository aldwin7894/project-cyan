# frozen_string_literal: true

class AnilistController < ApplicationController
  before_action :check_if_from_cloudfront

  def index; end

  def new; end

  def fetch_followers(following = [], followers = [], following_page = 1, followers_page = 1, following_done = false, followers_done = false)
    @success = false
    return @error = "Username can't be empty" if params[:username].blank?

    id = Rails.cache.fetch("ANILIST/#{params[:username]}/USER_ID", expires_in: 1.year, skip_nil: true) do
      query(AniList::UserIdQuery, username: params[:username]).user.id
    end

    captcha_valid = verify_recaptcha action: "captcha", minimum_score: 0.7
    unless captcha_valid || Rails.env.development?
      @error = "You're probably a bot, aren't you?"
      return render layout: false
    end

    @following_count = nil
    @followers_count = nil
    @following = following
    @followers = followers

    cooldown = Rails.cache.fetch("ANILIST/FOLLOW_CHECKER_CD")
    if Time.zone.now.to_i <= cooldown.to_i && !Rails.env.development?
      cd_mins = ((cooldown - Time.zone.now) / 60.0).round
      return @error = "On cooldown, please try again after #{cd_mins} #{'minute'.pluralize(cd_mins)}."
    end

    @following_page = following_page
    loop do
      break if @following_done

      sleep 0.3 unless Rails.env.development?
      data = query(AniList::UserFollowingQuery, user_id: id, page: @following_page)
      @following_count ||= data.page.page_info.total
      @following.push(*data.page.following.map(&:name))

      if data.page.page_info.has_next_page? == false
        @following_done = true
        break
      else
        @following_page += 1
      end
    end

    @followers_page = followers_page
    loop do
      break if @followers_done

      sleep 0.3 unless Rails.env.development?
      data = query(AniList::UserFollowersQuery, user_id: id, page: @followers_page)
      @followers_count ||= data.page.page_info.total
      @followers.push(*data.page.followers.map(&:name))

      if data.page.page_info.has_next_page? == false
        @followers_done = true
        break
      else
        @followers_page += 1
      end
    end


    Rails.cache.fetch("ANILIST/FOLLOW_CHECKER_CD", expires_in: 2.minutes) do
      2.minutes.from_now
    end
    @success = true
  rescue QueryError => error
    logger.tagged("ANILIST", "fetch_followers") do
      logger.error(error)
    end

    case error.to_s
    when "429 Too Many Requests"
      sleep 10
      fetch_followers(@following, @followers, @following_page, @followers_page, @following_done, @followers_done)
    when "404 Not Found"
      Rails.cache.write("ANILIST_FOLLOW_CHECKER_CD", nil)
      @error = "#{params[:username]} was not found or has a private profile."
    else
      @error = "Something went wrong, plesae try again later."
    end
  end
end
