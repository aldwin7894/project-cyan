# frozen_string_literal: true

module Shoko
  extend self
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

  def Shoko.get_series_fanart_by_name(name:, year:, mal_id:, alternatives: [])
    headers = {
      **JSON_HEADER
    }
    url = "Series/Search"
    series = nil
    name = name.downcase

    cache_key = "SHOKO/#{name.parameterize(separator: '_')}/FANART_URL"
    if Rails.cache.exist? cache_key
      Rails.logger.tagged("CACHE", "Shoko.get_series_fanart_by_name", cache_key) do
        Rails.logger.info("HIT")
      end
      return Rails.cache.fetch(cache_key)
    end

    Rails.logger.tagged("SHOKO", "FIND SERIES", name) do
      Rails.logger.info("START")
    end

    possible_queries = [
      { name:, mal_id: },
      { name: sanitize(name), mal_id: },
      { name: alternative(name), mal_id: },
      { name: "#{name} (#{year})", mal_id: },
      { name: "#{sanitize(name)} (#{year})", mal_id: },
      { name: "#{alternative(name)} (#{year})", mal_id: },
    ]
    alternatives.each do |alt|
      alt_name = alt&.[](:name)&.downcase
      alt_year = alt&.[](:year)
      alt_mal_id = alt&.[](:mal_id)

      possible_queries += [
        { name: alt_name, mal_id: },
        { name: sanitize(alt_name), mal_id: alt_mal_id },
        { name: alternative(alt_name), mal_id: alt_mal_id },
        { name: "#{alt_name} (#{year})", mal_id: alt_mal_id },
        { name: "#{sanitize(alt_name)} (#{alt_year})", mal_id: alt_mal_id },
        { name: "#{alternative(alt_name)} (#{alt_year})", mal_id: alt_mal_id }
      ] if alt_name.present? && alt_year.present? && alt_mal_id.present?
    end
    possible_queries.uniq!

    index = 0
    loop do
      break if index > possible_queries.length - 1
      query = {
        query: possible_queries[index][:name],
        fuzzy: true,
        limit: 1
      }
      res = HTTParty.get(BASE_URL + url, headers:, query:, timeout: 10, format: :plain)
      unless res.success?
        raise ApiError.new("Shoko API error")
      end

      res = JSON.parse res, symbolize_names: true

      if res.is_a?(Array) && res&.first&.[](:IDs)&.[](:MAL)&.include?(possible_queries[index][:mal_id])
        if res&.first&.[](:Images)&.[](:Fanarts).present?
          Rails.logger.tagged("SHOKO", "FIND SERIES", possible_queries[index][:name]) do
            Rails.logger.info("FOUND")
          end
          series = res
          break
        end
        Rails.logger.tagged("SHOKO", "FIND SERIES", possible_queries[index][:name]) do
          Rails.logger.info("NO FANARTS")
        end
      else
        Rails.logger.tagged("SHOKO", "FIND SERIES", possible_queries[index][:name]) do
          Rails.logger.info("NOT FOUND")
        end
      end

      index += 1
    end

    fanart_url = nil
    if series.is_a? Array
      fanart = series.first[:Images][:Fanarts].first
      source = fanart[:Source]
      id = fanart[:ID]

      Rails.logger.tagged("CACHE", "Shoko.get_series_fanart_by_name", cache_key) do
        Rails.logger.info("MISS")
      end
      fanart_url = Rails.cache.fetch(cache_key, expires_in: 1.month, skip_nil: true) do
        get_fanart_url(id:, source:)
      end
    end

    fanart_url
  rescue ApiError
    nil
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
