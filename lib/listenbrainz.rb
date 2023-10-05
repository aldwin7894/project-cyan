# frozen_string_literal: true
# typed: true

require "sorbet-runtime"

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

  class Client
    include HTTParty
    persistent_connection_adapter
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

    def get_loved_tracks(user:)
      headers = {
        **JSON_HEADER
      }

      offset = 0
      total = T.let(1, T.untyped)
      data = []
      loop do
        break if offset > total

        query = {
          score: 1,
          count: 1000,
          offset:
        }
        result = Rails.cache.fetch("LISTENBRAINZ/#{user}/LOVED_TRACKS/#{offset}", expires_in: 1.month, skip_nil: true) do
          sleep 0.1
          res = self.class.get("/feedback/user/#{user}/get-feedback", headers:, query:)
          unless res.success?
            raise ApiError.new(res["error"], res["code"])
          end

          res.to_h
        end

        data.push(*result["feedback"])
        total = result["total_count"]
        offset += 1000
      end

      data
    end
  end

  def self.get_cover_art_url(release_mbid:, size:)
    return nil unless release_mbid.present? && size.present?

    url = "#{CAA_BASE_URL}release/#{release_mbid}/front-#{size}"
    res = HTTParty.head(url, follow_redirects: false, timeout: 30, open_timeout: 10)
    return nil unless res.success? || res.redirection?

    url
  end
end
