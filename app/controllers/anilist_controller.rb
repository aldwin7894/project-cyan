# frozen_string_literal: true

class AnilistController < ApplicationController
  def index; end

  def new; end

  def fetch_followers
    @success = false
    return @error = "Username can't be empty" if params[:username].blank?

    id = Rails.cache.fetch("ANILIST_USER_ID_#{params[:username]}", expires_in: 1.week, skip_nil: true) do
      query(AniList::UserIdQuery, username: params[:username]).user.id
    end

    captcha_valid = verify_recaptcha action: "captcha", minimum_score: 0.7
    unless captcha_valid || Rails.env.development?
      @error = "You're probably a bot, aren't you?"
      return render layout: false
    end

    @following_count = nil
    @followers_count = nil
    @following = []
    @followers = []

    page = 1
    loop do
      data = query(AniList::UserFollowingQuery, user_id: id, page:)
      @following_count ||= data.page.page_info.total
      @following.push(*data.page.following.map(&:name))

      if data.page.page_info.has_next_page? == false
        break
      else
        page += 1
      end
    end

    page = 1
    loop do
      data = query(AniList::UserFollowersQuery, user_id: id, page:)
      @followers_count ||= data.page.page_info.total
      @followers.push(*data.page.followers.map(&:name))

      if data.page.page_info.has_next_page? == false
        break
      else
        page += 1
      end
    end
    @success = true
  rescue QueryError
    @error = "Username not found"
  end
end
