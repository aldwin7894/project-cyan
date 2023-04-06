# frozen_string_literal: true

module LastFM
  LASTFM_API_KEY = ENV.fetch("LASTFM_API_KEY")
  LASTFM_API_SECRET = ENV.fetch("LASTFM_API_SECRET")
  BASE_URL = "https://ws.audioscrobbler.com/2.0/"
  JSON_HEADER = {
    "Accept": "application/json",
    "Content-Type": "application/json",
  }

  class Error < StandardError; end
  class ApiError < Error
    attr_reader :code

    def initialize(message, code = nil)
      super(message)
      @code = code
    end
  end

  def LastFM.get_recent_tracks(user:, limit:, extended:)
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

    res = HTTParty.get(BASE_URL, headers:, query:, timeout: 10)
    unless res.success?
      raise ApiError.new(res["message"], res["error"])
    end

    res["recenttracks"]["track"]
  end

  def LastFM.get_top_artists(user:, period:, limit:)
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

    res = HTTParty.get(BASE_URL, headers:, query:, timeout: 10)
    unless res.success?
      raise ApiError.new(res["message"], res["error"])
    end

    res["topartists"]["artist"]
  end
end
