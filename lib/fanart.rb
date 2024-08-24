# frozen_string_literal: true
# typed: true

require "sorbet-runtime"
require "colorize"

module Fanart
  FANARTTV_API_KEY = ENV.fetch("FANART_API_KEY")
  BASE_URL = ENV.fetch("FANART_BASE_URL")
  JSON_HEADER = {
    "Accept": "text/plain",
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

  class Client
    include HTTParty
    base_uri BASE_URL
    default_timeout 30
    open_timeout 10
    CACHE_TAG = "CACHE".yellow
    FANART_TAG = "FANART".yellow

    def initialize
      @options = {
        headers: {
          **JSON_HEADER
        },
        query: {
          api_key: FANARTTV_API_KEY
        },
        timeout: 10,
        format: :plain,
      }
    end

    def get_fanart_by_tmdb_id(tmdb_id:)
      url = "/movies/#{tmdb_id}"
      cache_key = "FANART/TMDB/#{tmdb_id}"
      fanart_url = nil
      log_tag = "GET MOVIE FANART: TMDB".yellow

      if Rails.cache.exist? cache_key
        Rails.logger.tagged(CACHE_TAG, "FanartTV.get_fanart_by_tmdb_id".yellow, cache_key.yellow) do
          Rails.logger.info("HIT".green)
        end
        return Rails.cache.fetch(cache_key)
      end

      Rails.logger.tagged(CACHE_TAG, "FanartTV.get_fanart_by_tmdb_id".yellow, cache_key.yellow) do
        Rails.logger.info("MISS".red)
      end

      res = self.class.get(url, **@options)
      unless res.success?
        raise ApiError.new("Fanart API error")
      end

      res = JSON.parse res, symbolize_names: true
      if !res&.[](:moviebackground).is_a?(Array)
        Rails.logger.tagged(FANART_TAG, log_tag, tmdb_id.to_s.yellow) do
          Rails.logger.info("NOT FOUND".red)
        end
        return fanart_url
      end

      fanart = res[:moviebackground]&.sort_by { |x| [-x[:likes].to_i, -x[:id].to_i] }&.first
      if fanart.blank?
        Rails.logger.tagged(FANART_TAG, log_tag, tmdb_id.to_s.yellow) do
          Rails.logger.info("NO FANARTS".red)
        end
        return fanart_url
      end

      Rails.logger.tagged(FANART_TAG, log_tag, tmdb_id.to_s.yellow) do
        Rails.logger.info("FOUND".green)
      end
      fanart_url = fanart[:url]

      Rails.cache.write(cache_key, fanart_url, expires_in: 1.month)
      fanart_url
    rescue HTTParty::Error, ApiError
      nil
    end

    def get_fanart_by_tvdb_id(tvdb_id:)
      url = "/tv/#{tvdb_id}"
      cache_key = "FANART/TVDB/#{tvdb_id}"
      fanart_url = nil
      log_tag = "GET SERIES FANART: TVDB".yellow

      if Rails.cache.exist? cache_key
        Rails.logger.tagged(CACHE_TAG, "FanartTV.get_fanart_by_tvdb_id".yellow, cache_key.yellow) do
          Rails.logger.info("HIT".green)
        end
        return Rails.cache.fetch(cache_key)
      end

      Rails.logger.tagged(CACHE_TAG, "FanartTV.get_fanart_by_tvdb_id".yellow, cache_key.yellow) do
        Rails.logger.info("MISS".red)
      end

      res = self.class.get(url, **@options)
      unless res.success?
        raise ApiError.new("Fanart API error")
      end

      res = JSON.parse res, symbolize_names: true
      if !res&.[](:showbackground).is_a?(Array)
        Rails.logger.tagged(FANART_TAG, log_tag, tvdb_id.to_s.yellow) do
          Rails.logger.info("NOT FOUND".red)
        end
        return fanart_url
      end

      fanart = res[:showbackground]&.sort_by { |x| [-x[:likes].to_i, -x[:id].to_i] }&.first
      if fanart.blank?
        Rails.logger.tagged(FANART_TAG, log_tag, tvdb_id.to_s.yellow) do
          Rails.logger.info("NO FANARTS".red)
        end
        return fanart_url
      end

      Rails.logger.tagged(FANART_TAG, log_tag, tvdb_id.to_s.yellow) do
        Rails.logger.info("FOUND".green)
      end
      fanart_url = fanart[:url]

      Rails.cache.write(cache_key, fanart_url, expires_in: 1.month)
      fanart_url
    rescue HTTParty::Error, ApiError
      nil
    end
  end
end
