# frozen_string_literal: true
# typed: true

require "brotli"

module LastFM
  LASTFM_API_KEY = ENV.fetch("LASTFM_API_KEY")
  LASTFM_API_SECRET = ENV.fetch("LASTFM_API_SECRET")
  BASE_URL = "https://ws.audioscrobbler.com/2.0/"
  JSON_HEADER = {
    "Accept": "application/json",
    "Content-Type": "application/json",
    "Accept-Encoding": "br,gzip,deflate"
  }

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
    default_timeout 30
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

      Rails.cache.fetch("LASTFM/#{user}/RECENT_TRACKS", expires_in: 30.seconds, skip_nil: true) do
        res = self.class.get("/", headers:, query:)
        unless res.success?
          raise ApiError.new(res["message"], res["error"])
        end

        res["recenttracks"]["track"]
      end
    rescue HTTParty::Error => e
      raise ApiError.new(e.message)
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

      cache_key = "LASTFM/#{user}/TOP_ARTISTS"
      if Rails.cache.exist? cache_key
        Rails.logger.tagged("CACHE".yellow, "LastFM.get_top_artists".yellow, cache_key.yellow) do
          Rails.logger.info("HIT".green)
        end
        top_artists = Rails.cache.fetch(cache_key)
      else
        Rails.logger.tagged("CACHE".yellow, "LastFM.get_top_artists".yellow, cache_key.yellow) do
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
    rescue HTTParty::Error => e
      raise ApiError.new(e.message)
    end
  end

  def self.get_cover_art_url(track)
    url = T.let(track&.[]("image")&.[](2)&.[]("#text"), T.untyped)
    return nil unless url.present? && url.is_a?(String) && url.exclude?("2a96cbd8b46e442fc41c2b86b821562f")

    # res = self.class.head(url)
    # return nil unless res.success?

    url
  end
end
