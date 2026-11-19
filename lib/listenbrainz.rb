# frozen_string_literal: true
# typed: true

require "sorbet-runtime"
require "brotli"

module ListenBrainz
  LISTENBRAINZ_USER_TOKEN = Rails.application.credentials.config.dig(:LISTENBRAINZ_USER_TOKEN)
  CAA_BASE_URL = "https://coverartarchive.org/"
  BASE_URL = "https://api.listenbrainz.org/1/"
  JSON_HEADER = {
    "Accept": "application/json",
    "Content-Type": "application/json",
    "Accept-Encoding": "br,gzip,deflate",
    "Authorization": "Token #{LISTENBRAINZ_USER_TOKEN}"
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
    persistent_connection_adapter name: "listenbrainz",
      pool_size: 2,
      idle_timeout: 10,
      keep_alive: 30
    base_uri BASE_URL
    default_timeout 20
    open_timeout 10

    def get_recent_tracks(user:, limit:)
      headers = {
        **JSON_HEADER
      }
      query = {
        count: limit
      }
      log_tag = "ListenBrainz.get_recent_tracks".yellow
      cache_key = "LISTENBRAINZ/#{user}/RECENT_TRACKS"

      if Rails.cache.exist?(cache_key)
        Rails.logger.tagged(CACHE_TAG, log_tag, user.to_s.yellow) do
          Rails.logger.info("HIT".green)
        end
        return Rails.cache.fetch(cache_key)
      end

      res = self.class.get("/user/#{user}/listens", headers:, query:)
      unless res.success?
        raise ApiError.new(res["error"], res["code"])
      end

      Rails.cache.write(cache_key, res["payload"], expires_in: 5.minutes)
      res["payload"]
    rescue HTTParty::Error, ApiError => e
      Rails.logger.tagged("LISTENBRAINZ".yellow, log_tag, user.to_s.yellow) do
        Rails.logger.error("ERROR: #{e.message}".red)
      end

      raise e
    end

    def get_now_playing(user:)
      headers = {
        **JSON_HEADER
      }
      log_tag = "ListenBrainz.get_now_playing".yellow
      cache_key = "LISTENBRAINZ/#{user}/NOW_PLAYING"

      if Rails.cache.exist?(cache_key)
        Rails.logger.tagged(CACHE_TAG, log_tag, user.to_s.yellow) do
          Rails.logger.info("HIT".green)
        end
        return Rails.cache.fetch(cache_key)
      end

      Rails.logger.tagged(CACHE_TAG, log_tag, cache_key.yellow) do
        Rails.logger.info("MISS".red)
      end


      res = self.class.get("/user/#{user}/playing-now", headers:)
      unless res.success?
        raise ApiError.new(res["error"], res["code"])
      end

      Rails.cache.write(cache_key, res["payload"], expires_in: 30.seconds)
      res["payload"]
    rescue HTTParty::Error, ApiError => e
      Rails.logger.tagged("LISTENBRAINZ".yellow, log_tag, user.to_s.yellow) do
        Rails.logger.error("ERROR: #{e.message}".red)
      end

      raise e
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
      log_tag = "ListenBrainz.get_loved_tracks".yellow

      res = self.class.get("/feedback/user/#{user}/get-feedback", headers:, query:)
      unless res.success?
        raise ApiError.new(res["error"], res["code"])
      end

      result = res.to_h
      data.push(*result["feedback"])
      total = result["total_count"].to_i
      ratelimit_remaining = res.headers["x-ratelimit-remaining"].to_i

      { data:, total:, ratelimit_remaining: }
    rescue HTTParty::Error, ApiError => e
      Rails.logger.tagged("LISTENBRAINZ".yellow, log_tag, user.to_s.yellow) do
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

  def self.get_cover_art_url(track:, size:)
    url = T.let(nil, T.nilable(String))
    track_metadata = track.dig("track_metadata")
    return url unless track_metadata.present? && size.present?

    track_artist = track_metadata&.dig("artist_name")
    track_name = track_metadata&.dig("track_name")
    cache_hash = Digest::SHA256.hexdigest("#{track_artist}-#{track_name}-#{size}")
    cache_key = "LISTENBRAINZ/COVER_ART/#{cache_hash}"

    if Rails.cache.exist?(cache_key)
      Rails.logger.tagged("CACHE".yellow, "ListenBrainz.get_cover_art_url".yellow, "#{track_artist}-#{track_name}-#{size}".yellow) do
        Rails.logger.info("HIT".green)
      end
      return Rails.cache.fetch(cache_key)
    end

    release_mbid = track_metadata.dig("additional_info", "release_mbid")
    release_group_mbid = track_metadata.dig("additional_info", "release_group_mbid")
    caa_id = track_metadata.dig("additional_info", "caa_id")
    caa_release_mbid = track_metadata.dig("additional_info", "caa_release_mbid")
    fallback_release_mbid = track_metadata.dig("mbid_mapping", "release_mbid")
    fallback_release_group_mbid = track_metadata.dig("mbid_mapping", "release_group_mbid")

    candidate_urls = []
    candidate_urls << "#{CAA_BASE_URL}release/#{release_mbid}/front-#{size}" if release_mbid.present?
    candidate_urls << "#{CAA_BASE_URL}release-group/#{release_group_mbid}/front-#{size}" if release_group_mbid.present?
    candidate_urls << "#{CAA_BASE_URL}release/#{caa_release_mbid}/#{caa_id}-#{size}" if caa_id.present? && caa_release_mbid.present?
    candidate_urls << "#{CAA_BASE_URL}release/#{fallback_release_mbid}/front-#{size}" if fallback_release_mbid.present?
    candidate_urls << "#{CAA_BASE_URL}release-group/#{fallback_release_group_mbid}/front-#{size}" if fallback_release_group_mbid.present?

    candidate_urls.uniq.each do |candidate_url|
      if url_exists?(candidate_url)
        url = candidate_url
        Rails.cache.write(cache_key, url, expires_in: 1.month)
        break
      end
    end

    url
  end
end
