# frozen_string_literal: true

module Spotify
  ACCESS_TOKEN_URL = "https://accounts.spotify.com/api/token"
  GET_ARTIST_URL = "https://api.spotify.com/v1/artists"
  SEARCH_URL = "https://api.spotify.com/v1/search"
  JSON_HEADER = {
    "Accept": "application/json",
    "Content-Type": "application/json",
  }

  def Spotify.get_access_token
    token = Rails.cache.fetch("SPOTIFY_ACCESS_TOKEN", expires_in: 1.hour, skip_nil: true) do
      authorization = Base64.urlsafe_encode64(ENV.fetch("SPOTIFY_CLIENT_ID") + ":" + ENV.fetch("SPOTIFY_CLIENT_SECRET"))
      headers = {
        "Authorization": "Basic #{authorization}",
        "Content-Type" => "application/x-www-form-urlencoded",
        "charset" => "utf-8"
      }
      body = "grant_type=client_credentials"

      res = HTTParty.post(ACCESS_TOKEN_URL, headers:, body:, timeout: 10)
      return if res.code >= 300
      res["access_token"]
    end

    token
  end

  def Spotify.get_artists_images(ids)
    if ids.blank? then return end
    headers = {
      **JSON_HEADER,
      "Authorization": "Bearer #{Spotify.get_access_token}"
    }
    query = {
      ids:
    }

    res = HTTParty.get(GET_ARTIST_URL, headers:, query:, timeout: 10)
    return if res.code >= 300
    artists = JSON.parse(res.body)
    Rails.cache.fetch("#{ids.remove(",")}/SPOTIFY_ARTIST_IMAGES", expires_in: 1.week, skip_nil: true) do
      artists&.[]("artists")&.pluck("images")&.map { |x| x[1]["url"] }
    end
  end

  def Spotify.get_artist_id_by_name(name)
    if name.blank? then return end

    whitelist = SpotifyArtistWhitelist.find_by(name:)
    if whitelist.present? then return whitelist.spotify_id end

    headers = {
      **JSON_HEADER,
      "Authorization": "Bearer #{Spotify.get_access_token}"
    }

    query = {
      q: name,
      type: "artist",
      limit: 1
    }
    res = HTTParty.get(SEARCH_URL, headers:, query:, timeout: 10)
    return if res.code >= 300
    artist = JSON.parse(res.body)
    artist&.[]("artists")&.[]("items")&.[](0)&.[]("uri")&.split(":")&.last
  end
end
