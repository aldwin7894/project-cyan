# frozen_string_literal: true
# typed: true

module AniList
  Client = Graphlient::Client.new(
    "https://graphql.anilist.co",
    headers: {
      "Authorization": ENV.fetch("ANILIST_OAUTH_TOKEN"),
    },
    http_options: {
      read_timeout: 20,
      write_timeout: 30
    },
    schema_path: "db/schema.json"
  )

  UserIdQuery = Client.parse <<~'GRAPHQL'
    query($username: String) {
      User(name: $username) {
        id
      }
    }
  GRAPHQL

  UserFollowersQuery = Client.parse <<~'GRAPHQL'
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

  UserFollowingQuery = Client.parse <<~'GRAPHQL'
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

  UserStatisticsQuery = Client.parse <<~'GRAPHQL'
    query($user_id: Int!) {
      User(id: $user_id) {
        id
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

  UserAnimeActivitiesQuery = Client.parse <<~'GRAPHQL'
    query($user_id: Int!, $page: Int, $per_page: Int, $date: Int) {
      Page(page: $page, perPage: $per_page) {
        pageInfo {
          hasNextPage
        }
        activities(userId: $user_id, createdAt_greater: $date, sort: ID, type: ANIME_LIST) {
          ... on ListActivity {
            id
            media {
              format
              bannerImage
              siteUrl
              duration
              title {
                userPreferred
                english
              }
              countryOfOrigin
              seasonYear
              idMal
              coverImage {
                extraLarge
                color
              }
              studios(isMain: true, sort: FAVOURITES_DESC) {
                nodes {
                  name
                  isAnimationStudio
                }
              }
              genres
              mediaListEntry {
                score
              }
              relations {
                edges {
                  relationType(version: 2)
                  node {
                    title {
                      userPreferred
                    }
                    format
                    seasonYear
                    idMal
                  }
                }
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

  UserAnimeActivitiesLastPageQuery = Client.parse <<~'GRAPHQL'
    query($user_id: Int!, $page: Int, $per_page: Int, $date: Int) {
      Page(page: $page, perPage: $per_page) {
        pageInfo {
          lastPage
        }
        activities(userId: $user_id, createdAt_greater: $date, sort: ID_DESC, type: ANIME_LIST) {
          __typename
        }
      }
    }
  GRAPHQL

  UserAnimeActivitiesLastIdQuery = Client.parse <<~'GRAPHQL'
    query($user_id: Int!, $page: Int, $per_page: Int, $date: Int) {
      Page(page: $page, perPage: $per_page) {
        pageInfo {
          hasNextPage
        }
        activities(userId: $user_id, createdAt_greater: $date, sort: ID, type: ANIME_LIST) {
          ... on ListActivity {
            id
          }
        }
      }
    }
  GRAPHQL
end
