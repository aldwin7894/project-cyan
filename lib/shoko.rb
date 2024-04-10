# frozen_string_literal: true
# typed: true

require "sorbet-runtime"

module Shoko
  SHOKO_API_KEY = ENV.fetch("SHOKO_API_KEY")
  BASE_URL = ENV.fetch("SHOKO_BASE_URL")
  JSON_HEADER = {
    "Accept": "text/plain",
    "Content-Type": "application/json",
    "ApiKey": SHOKO_API_KEY
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

    def initialize
      @options = {
        headers: {
          **JSON_HEADER
        },
        timeout: 10,
        format: :plain
      }
    end

    def find_series(name:, year:, mal_id:, alternatives: [])
      url = "/Series/Search"
      series = T.let(nil, T.nilable(T::Array[T.untyped]))
      name = name.downcase

      cache_key = "SHOKO/SERIES/#{name.downcase.gsub(/\s/, "_")}"
      if Rails.cache.exist? cache_key
        Rails.logger.tagged("CACHE", "Shoko.find_series", cache_key) do
          Rails.logger.info("HIT")
        end
        return Rails.cache.fetch(cache_key)
      end

      Rails.logger.tagged("CACHE", "Shoko.find_series", cache_key) do
        Rails.logger.info("MISS")
      end

      possible_queries = [
        { name:, mal_id: },
        { name: sanitize(name), mal_id: },
        { name: alternative(name), mal_id: },
      ]
      possible_queries += [
        { name: "#{name} (#{year})", mal_id: },
        { name: "#{sanitize(name)} (#{year})", mal_id: },
        { name: "#{alternative(name)} (#{year})", mal_id: },
      ] if year.present?

      alternatives.each do |alt|
        alt_name = alt&.[](:name)&.downcase
        alt_year = alt&.[](:year)
        alt_mal_id = alt&.[](:mal_id)

        possible_queries += [
          { name: alt_name, mal_id: },
          { name: sanitize(alt_name), mal_id: alt_mal_id },
          { name: alternative(alt_name), mal_id: alt_mal_id },
        ] if alt_name.present?

        possible_queries += [
          { name: "#{alt_name} (#{year})", mal_id: alt_mal_id },
          { name: "#{sanitize(alt_name)} (#{alt_year})", mal_id: alt_mal_id },
          { name: "#{alternative(alt_name)} (#{alt_year})", mal_id: alt_mal_id }
        ] if alt_year.present?
      end
      possible_queries.uniq!

      Rails.logger.tagged("SHOKO", "FIND SERIES", name) do
        Rails.logger.info("START")
      end

      index = 0
      loop do
        break if index > possible_queries.length - 1

        query = {
          query: possible_queries[index]&.[](:name),
          fuzzy: true,
          limit: 1
        }
        res = self.class.get(url, query:, **@options)
        unless res.success?
          raise ApiError.new("Shoko API error")
        end

        res = JSON.parse res, symbolize_names: true
        if res.is_a?(Array) && res.first&.[](:IDs)&.[](:MAL)&.include?(possible_queries[index]&.[](:mal_id))
          series = res.first
          break
        end

        Rails.logger.tagged("SHOKO", "FIND SERIES", possible_queries[index]&.[](:name)) do
          Rails.logger.info("NOT FOUND")
        end
        index += 1
      end

      Rails.cache.write(cache_key, series, expires_in: 1.month)
      series
    rescue ApiError
      nil
    end

    def get_fanart_by_series(series:)
      return nil if series.blank? || series&.[](:IDs)&.[](:ID).blank?

      cache_key = "SHOKO/FANART/#{series[:IDs][:ID]}"
      fanart_url = nil

      if Rails.cache.exist? cache_key
        Rails.logger.tagged("CACHE", "Shoko.get_series_fanart_by_name", cache_key) do
          Rails.logger.info("HIT")
        end
        return Rails.cache.fetch(cache_key)
      end

      Rails.logger.tagged("CACHE", "Shoko.get_series_fanart_by_name", cache_key) do
        Rails.logger.info("MISS")
      end

      if series&.[](:Images)&.[](:Fanarts).blank?
        Rails.logger.tagged("SHOKO", "GET FANART", series[:IDs][:ID]) do
          Rails.logger.info("NO FANARTS")
        end
        return fanart_url
      end

      Rails.logger.tagged("SHOKO", "GET FANART", series[:match]) do
        Rails.logger.info("FOUND")
      end

      fanart = series[:Images][:Fanarts].first
      source = fanart[:Source]
      id = fanart[:ID]

      fanart_url = Rails.cache.fetch(cache_key, expires_in: 1.month, skip_nil: true) do
        get_fanart_url(id:, source:)
      end

      fanart_url
    end

    private
      def get_fanart_url(id:, source:)
        "#{BASE_URL}Image/#{source}/Fanart/#{id}"
      end

      def alternative(string)
        string = string.gsub(/\b(wo)\b/, "o")
        string = string.gsub(/★|☆/, " ")
        string = string.gsub(/ü/, "u")
        string = string.gsub(/mahoutsukai/, "mahou tsukai")
        string = string.gsub(/[\[\]]/, "")
        string = string.gsub(/(season|part) \d+/, "")
        string = string.gsub(/\d+$/, "")
        string = string.gsub(/(\d{1}st|\d{1}nd|\d{1}rd|\d+th) season/, "")
        string.strip!
        string
      end

      def sanitize(string)
        whitelisted_regex = /[^0-9A-Za-z \-:!\/().?,★☆×'";\[\]]/
        string = string.gsub(whitelisted_regex, "")
        string = string.gsub(/(?<=\s)-(?=[A-Za-z])/, "")
        string = string.gsub(/(?<=[A-Za-z])-(?=\s)/, "")
        string.strip!
        string
      end
  end
end
