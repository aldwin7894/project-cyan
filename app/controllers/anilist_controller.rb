# frozen_string_literal: true

class AnilistController < ApplicationController
  def index; end

  def new; end

  def fetch_followers(following = [], followers = [], following_page = 1, followers_page = 1, following_done = false, followers_done = false)
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
      @following = following
      @followers = followers

      cooldown = Rails.cache.fetch("ANILIST_FOLLOW_CHECKER_CD")
      if Time.zone.now.to_i <= cooldown.to_i
        cd_mins = ((cooldown - Time.zone.now) / 60.0).round
        return @error = "On cooldown, please try again after #{cd_mins} #{'minute'.pluralize(cd_mins)}."
      end

      @following_page = following_page
      loop do
        break if @following_done

        sleep 0.5
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

        sleep 0.5
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


      Rails.cache.fetch("ANILIST_FOLLOW_CHECKER_CD", expires_in: 2.minutes) do
        now = Time.zone.now
        now += 2.minutes
        now
      end
      @success = true
    rescue QueryError => error
      if error.to_s.include? "429 Too Many Requests"
        sleep 15
        fetch_followers(@following, @followers, @following_page, @followers_page, @following_done, @followers_done)
        return
      end
      Rails.cache.write("ANILIST_FOLLOW_CHECKER_CD", nil)
      @error = "Username not found"
    end
  end
end
