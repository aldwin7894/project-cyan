# frozen_string_literal: true

class AnilistController < ApplicationController
  def show
    id = Rails.cache.fetch("ANILIST_USER_ID_#{params[:id]}", expires_in: 1.week, skip_nil: true) do
      query(AniList::UserIdQuery, username: params[:id]).user.id
    end
    @following_count = nil
    @followers_count = nil
    @following = []
    @followers = []

    page = 1
    loop do
      data = query(AniList::UserFollowingQuery, user_id: id, page: page)
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
      data = query(AniList::UserFollowersQuery, user_id: id, page: page)
      @followers_count ||= data.page.page_info.total
      @followers.push(*data.page.followers.map(&:name))

      if data.page.page_info.has_next_page? == false
        break
      else
        page += 1
      end
    end
  end
end
