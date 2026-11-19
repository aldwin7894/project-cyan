# frozen_string_literal: true
# typed: true

require "brotli"

module LastFM
  LASTFM_API_KEY = Rails.application.credentials.config.dig(:LASTFM_API_KEY)
  LASTFM_API_SECRET = Rails.application.credentials.config.dig(:LASTFM_API_SECRET)
  BASE_URL = "https://ws.audioscrobbler.com/2.0/"
  JSON_HEADER = {
    "Accept": "application/json",
    "Content-Type": "application/json",
    "Accept-Encoding": "br,gzip,deflate"
  }
  CACHE_TAG = "CACHE".yellow

  class Error < StandardError; end
  class ApiError < Error
    attr_reader :code

    def initialize(message, code = nil)
      super(message)
      @code = code
    end
  end

  class Client
    include HTTParty
    persistent_connection_adapter name: "lastfm",
      pool_size: 2,
      idle_timeout: 10,
      keep_alive: 30
    base_uri BASE_URL
    default_timeout 20
    open_timeout 10

    def get_recent_tracks(user:, limit:, extended:)
      headers = {
        **JSON_HEADER
      }
      query = {
        api_key: LASTFM_API_KEY,
        extended:,
        format: "json",
        limit:,
        method: "user.getRecentTracks",
        user:,
      }
      log_tag = "LastFM.get_recent_tracks".yellow
      cache_key = "LASTFM/#{user}/RECENT_TRACKS"

      if Rails.cache.exist?(cache_key)
        Rails.logger.tagged(CACHE_TAG, log_tag, user.to_s.yellow) do
          Rails.logger.info("HIT".green)
        end
        return Rails.cache.fetch(cache_key)
      end


      res = self.class.get("/", headers:, query:)
      unless res.success?
        raise ApiError.new(res["message"], res["error"])
      end

      Rails.cache.write(cache_key, res["recenttracks"]["track"], expires_in: 2.minutes)
      res["recenttracks"]["track"]
    rescue HTTParty::Error, ApiError => e
      Rails.logger.tagged("LASTFM".yellow, log_tag, user.to_s.yellow) do
        Rails.logger.error("ERROR: #{e.message}".red)
      end

      raise e
    end

    def get_top_artists(user:, period:, limit:)
      headers = {
        **JSON_HEADER
      }
      query = {
        api_key: LASTFM_API_KEY,
        format: "json",
        limit:,
        method: "user.getTopArtists",
        period:,
        user:,
      }
      log_tag = "LastFM.get_top_artists".yellow

      cache_key = "LASTFM/#{user}/TOP_ARTISTS"
      if Rails.cache.exist? cache_key
        Rails.logger.tagged("CACHE".yellow, log_tag, cache_key.yellow) do
          Rails.logger.info("HIT".green)
        end
        top_artists = Rails.cache.fetch(cache_key)
      else
        Rails.logger.tagged("CACHE".yellow, log_tag, cache_key.yellow) do
          Rails.logger.info("MISS".red)
        end
        top_artists = Rails.cache.fetch(cache_key, expires_in: 1.month, skip_nil: true) do
          res = self.class.get("/", headers:, query:)
          unless res.success?
            raise ApiError.new(res["message"], res["error"])
          end

          res["topartists"]["artist"]
        end
      end

      top_artists
    rescue HTTParty::Error, ApiError => e
      Rails.logger.tagged("LASTFM".yellow, log_tag, user.to_s.yellow) do
        Rails.logger.error("ERROR: #{e.message}".red)
      end

      raise e
    end
  end

  def self.url_exists?(url)
    response = HTTParty.head(url, follow_redirects: true, timeout: 5)
    response.success?
  rescue StandardError
    false
  end

  def self.get_cover_art_url(track)
    url = T.let(track&.[]("image")&.[](2)&.[]("#text"), T.nilable(String))
    return nil unless url.present? && url.is_a?(String) && url.exclude?("2a96cbd8b46e442fc41c2b86b821562f")

    cache_key = "LASTFM/COVER_ART/#{Digest::SHA256.hexdigest(url)}"

    if Rails.cache.exist?(cache_key)
      Rails.logger.tagged(CACHE_TAG, "LastFM.get_cover_art_url".yellow, url.yellow) do
        Rails.logger.info("HIT".green)
      end
      return Rails.cache.fetch(cache_key)
    end

    if url_exists?(url)
      Rails.cache.write(cache_key, url, expires_in: 1.month)
    end

    url
  end
end
