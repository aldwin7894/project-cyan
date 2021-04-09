# frozen_string_literal: true

class AnilistController < ApplicationController
  UserIdQuery = AniList::Client.parse <<-'GRAPHQL'
    query($username: String) {
      User(name: $username) {
        id
      }
    }
  GRAPHQL

  UserFollowersQuery = AniList::Client.parse <<-'GRAPHQL'
    query($user_id: Int!, $page: Int) {
      Page(page: $page, perPage: 50) {
        pageInfo {
          total
          hasNextPage
        }
        followers(userId: $user_id, sort: USERNAME) {
          name
        }
      }
    }
  GRAPHQL

  UserFollowingQuery = AniList::Client.parse <<-'GRAPHQL'
    query($user_id: Int!, $page: Int) {
      Page(page: $page, perPage: 50) {
        pageInfo {
          total
          hasNextPage
        }
        following(userId: $user_id, sort: USERNAME) {
          name
        }
      }
    }
  GRAPHQL

  def show
    id = query(UserIdQuery, username: params[:id]).user.id
    @following_count = nil
    @followers_count = nil
    @following = []
    @followers = []

    page = 1
    loop do
      data = query(UserFollowingQuery, user_id: id, page: page)
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
      data = query(UserFollowersQuery, user_id: id, page: page)
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
