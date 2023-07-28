# frozen_string_literal: true

module Spotify
  ACCESS_TOKEN_URL = "https://accounts.spotify.com/api/token"
  SPOTIFY_BASE_URL = "https://api.spotify.com/v1"
  JSON_HEADER = {
    "Accept": "application/json",
    "Content-Type": "application/json",
  }

  def Spotify.get_access_token
    token = Rails.cache.fetch("SPOTIFY/ACCESS_TOKEN", expires_in: 1.hour, skip_nil: true) do
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

  def Spotify.get_artists_images(ids:)
    if ids.blank? then return end
    headers = {
      **JSON_HEADER,
      "Authorization": "Bearer #{Spotify.get_access_token}"
    }
    query = {
      ids:
    }

    cache_key = "SPOTIFY/#{ids.remove(",")}/ARTIST_IMAGES"
    if Rails.cache.exist? cache_key
      Rails.logger.tagged("CACHE", "Spotify.get_artists_images", cache_key) do
        Rails.logger.info("HIT")
      end
      artist_images = Rails.cache.fetch(cache_key)
    else
      Rails.logger.tagged("CACHE", "Spotify.get_artists_images", cache_key) do
        Rails.logger.info("MISS")
      end
      artist_images = Rails.cache.fetch(cache_key, expires_in: 1.week, skip_nil: true) do
        res = HTTParty.get("#{SPOTIFY_BASE_URL}/artists", headers:, query:, timeout: 10)
        return if res.code >= 300

        artists = JSON.parse(res.body)
        artists&.[]("artists")&.pluck("images")&.map { |x| x[1]["url"] }
      end
    end

    artist_images
  end

  def Spotify.get_artist_id_by_name(name:)
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

    cache_key = "SPOTIFY/#{name.downcase.gsub(/\s/, "_")}/ARTIST_ID"
    if Rails.cache.exist? cache_key
      Rails.logger.tagged("CACHE", "Spotify.get_artist_id_by_name", cache_key) do
        Rails.logger.info("HIT")
      end
      artist_id = Rails.cache.fetch(cache_key)
    else
      Rails.logger.tagged("CACHE", "Spotify.get_artist_id_by_name", cache_key) do
        Rails.logger.info("MISS")
      end
      artist_id = Rails.cache.fetch(cache_key, expires_in: 1.month, skip_nil: true) do
        res = HTTParty.get("#{SPOTIFY_BASE_URL}/search", headers:, query:, timeout: 10)
        return if res.code >= 300

        artist = JSON.parse(res.body)
        artist&.[]("artists")&.[]("items")&.[](0)&.[]("uri")&.split(":")&.last
      end
    end

    artist_id
  end

  def Spotify.get_album_art(album_id:)
    if album_id.blank? then return end

    headers = {
      **JSON_HEADER,
      "Authorization": "Bearer #{Spotify.get_access_token}"
    }

    cache_key = "SPOTIFY/#{album_id}/ALBUM_ART"
    if Rails.cache.exist? cache_key
      Rails.logger.tagged("CACHE", "Spotify.get_album_art", cache_key) do
        Rails.logger.info("HIT")
      end
      album_art = Rails.cache.fetch(cache_key)
    else
      Rails.logger.tagged("CACHE", "Spotify.get_album_art", cache_key) do
        Rails.logger.info("MISS")
      end
      album_art = Rails.cache.fetch(cache_key, expires_in: 1.month, skip_nil: true) do
        res = HTTParty.get("#{SPOTIFY_BASE_URL}/albums/#{album_id}", headers:, timeout: 10)
        return if res.code >= 300

        album = JSON.parse(res.body)
        album&.[]("images")&.first&.[]("url")
      end
    end

    album_art
  end
end
