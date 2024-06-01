# frozen_string_literal: true
# typed: true

require "sorbet-runtime"
require "brotli"

module ListenBrainz
  LISTENBRAINZ_USER_TOKEN = ENV.fetch("LISTENBRAINZ_USER_TOKEN")
  CAA_BASE_URL = "https://coverartarchive.org/"
  BASE_URL = "https://api.listenbrainz.org/1/"
  JSON_HEADER = {
    "Accept": "application/json",
    "Content-Type": "application/json",
    "Accept-Encoding": "br,gzip,deflate",
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

  class Client
    include HTTParty
    persistent_connection_adapter name: "listenbrainz",
      pool_size: 2,
      idle_timeout: 10,
      keep_alive: 30
    base_uri BASE_URL
    default_timeout 30
    open_timeout 10

    def get_recent_tracks(user:, limit:)
      headers = {
        **JSON_HEADER
      }
      query = {
        count: limit
      }

      Rails.cache.fetch("LISTENBRAINZ/#{user}/RECENT_TRACKS", expires_in: 5.minutes, skip_nil: true) do
        res = self.class.get("/user/#{user}/listens", headers:, query:)
        unless res.success?
          raise ApiError.new(res["error"], res["code"])
        end

        res["payload"]
      end
    end

    def get_now_playing(user:)
      headers = {
        **JSON_HEADER
      }

      Rails.cache.fetch("LISTENBRAINZ/#{user}/NOW_PLAYING", expires_in: 2.minutes, skip_nil: true) do
        res = self.class.get("/user/#{user}/playing-now", headers:)
        unless res.success?
          raise ApiError.new(res["error"], res["code"])
        end

        res["payload"]
      end
    end

    def get_loved_tracks(user:, offset: 0)
      headers = {
        **JSON_HEADER
      }

      data = []
      query = {
        score: 1,
        count: 1000,
        offset:
      }

      res = self.class.get("/feedback/user/#{user}/get-feedback", headers:, query:)
      unless res.success?
        raise ApiError.new(res["error"], res["code"])
      end

      result = res.to_h
      data.push(*result["feedback"])
      total = result["total_count"].to_i

      { data:, total: }
    end
  end

  def self.get_cover_art_url(track:, size:)
    track_metadata = track&.[]("track_metadata")
    return nil unless track_metadata.present? && size.present?

    release_mbid = track_metadata&.[]("mbid_mapping")&.[]("caa_release_mbid")
    release_mbid ||= track_metadata&.[]("mbid_mapping")&.[]("release_mbid")
    release_mbid ||= track_metadata&.[]("additional_info")&.[]("caa_release_mbid")
    release_mbid ||= track_metadata&.[]("additional_info")&.[]("release_mbid")
    return nil if release_mbid.blank?

    url = "#{CAA_BASE_URL}release/#{release_mbid}/front-#{size}"
    # res = self.class.head(url, follow_redirects: false)
    # return nil unless res.success? || res.redirection?

    url
  end
end
