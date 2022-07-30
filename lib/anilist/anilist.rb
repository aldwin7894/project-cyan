# frozen_string_literal: true

require "graphql/client"
require "graphql/client/http"

module AniList
  Http ||= GraphQL::Client::HTTP.new("https://graphql.anilist.co")

  # Fetch latest schema on init, this will make a network request
  Schema ||= GraphQL::Client.load_schema(Dir[File.join(Rails.root, "db", "schema.json")][0])

  Client ||= GraphQL::Client.new(schema: Schema, execute: Http)

  UserIdQuery = Client.parse <<-'GRAPHQL'
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

  UserStatisticsQuery = AniList::Client.parse <<-'GRAPHQL'
    query($user_id: Int!) {
      User(id: $user_id) {
        statistics {
          anime {
            count
            statuses {
              count
              status
            }
            meanScore
            minutesWatched
            episodesWatched
            genres {
              genre
              count
            },
            studios {
              count
              studio {
                name
              }
            }
            formats {
              count
              format
              minutesWatched
            }
          }
        }
      }
    }
  GRAPHQL

  UserAnimeActivitiesQuery  = AniList::Client.parse <<-'GRAPHQL'
    query($user_id: Int!, $page: Int, $per_page: Int, $date: Int) {
      Page(page: $page, perPage: $per_page) {
        pageInfo {
          total
          hasNextPage
        }
        activities(userId: $user_id, createdAt_greater: $date, sort: ID_DESC, type: ANIME_LIST) {
          __typename
          ... on ListActivity {
            media {
              format
              bannerImage
              siteUrl
              duration
              title {
                userPreferred
              }
              coverImage {
                large
              }
            }
            createdAt
            status
            progress
            siteUrl
          }
        }
      }
    }
  GRAPHQL
end
