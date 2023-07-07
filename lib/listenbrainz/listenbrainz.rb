# frozen_string_literal: true

module ListenBrainz
  LISTENBRAINZ_USER_TOKEN = ENV.fetch("LISTENBRAINZ_USER_TOKEN")
  CAA_BASE_URL = "https://coverartarchive.org/"
  BASE_URL = "https://api.listenbrainz.org/1/"
  JSON_HEADER = {
    "Accept": "application/json",
    "Content-Type": "application/json",
    "Authorization": "Token #{LISTENBRAINZ_USER_TOKEN}"
  }

  class Error < StandardError; end
  class ApiError < Error
    attr_reader :code

    def initialize(message, code = nil)
      super(message)
      @code = code
    end
  end

  def ListenBrainz.get_recent_tracks(user:, limit:)
    headers = {
      **JSON_HEADER
    }
    query = {
      count: limit
    }

    Rails.cache.fetch("LISTENBRAINZ/#{user}/RECENT_TRACKS", expires_in: 5.minutes, skip_nil: true) do
      res = HTTParty.get("#{BASE_URL}/user/#{user}/listens", headers:, query:, timeout: 10)
      unless res.success?
        raise ApiError.new(res["error"], res["code"])
      end

      res["payload"]
    end
  end

  def ListenBrainz.get_now_playing(user:)
    headers = {
      **JSON_HEADER
    }

    Rails.cache.fetch("LISTENBRAINZ/#{user}/NOW_PLAYING", expires_in: 30.seconds, skip_nil: true) do
      res = HTTParty.get("#{BASE_URL}/user/#{user}/playing-now", headers:, timeout: 10)
      unless res.success?
        raise ApiError.new(res["error"], res["code"])
      end

      res["payload"]
    end
  end

  def ListenBrainz.get_loved_tracks(user:)
    headers = {
      **JSON_HEADER
    }

    Rails.cache.fetch("LISTENBRAINZ/#{user}/LOVED_TRACKS", expires_in: 1.day, skip_nil: true) do
      res = HTTParty.get("#{BASE_URL}/feedback/user/#{user}/get-feedback", headers:, timeout: 10)
      unless res.success?
        raise ApiError.new(res["error"], res["code"])
      end

      res["feedback"]
    end
  end

  def ListenBrainz.get_cover_art_url(release_mbid:, size:)
    return nil unless release_mbid.present? && size.present?

    url = "#{CAA_BASE_URL}release/#{release_mbid}/front-#{size}"
    res = HTTParty.head(url)
    return nil unless res.success?

    url
  end
end
