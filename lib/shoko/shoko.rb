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

  def Shoko.get_series_fanart_by_name(name:, year:, mal_id:, parent_name: nil, parent_year: nil, parent_mal_id: nil)
    headers = {
      **JSON_HEADER
    }
    url = "Series/Search"
    series = nil
    name.gsub!(/[^0-9A-Za-z !\/()]/, "")
    name.gsub!(/[^-]/, " ")
    parent_name&.gsub!(/[^0-9A-Za-z !\/()]/, "")
    parent_name&.gsub!(/[^-]/, " ")
    possible_queries = [
      { name:, mal_id: },
      { name: "#{name} (#{year})", mal_id: },
    ]
    possible_queries += [
      { name: parent_name, mal_id: parent_mal_id },
      { name: "#{parent_name} (#{parent_year})", mal_id: parent_mal_id }
    ] if parent_name.present? && parent_year.present? && parent_mal_id.present?

    index = 0
    loop do
      break if index > possible_queries.length - 1
      query = {
        query: possible_queries[index][:name],
        fuzzy: false,
        limit: 1
      }
      res = HTTParty.get(BASE_URL + url, headers:, query:, timeout: 10, format: :plain)
      unless res.success?
        raise ApiError.new(res["message"], res["error"])
        break
      end

      res = JSON.parse res, symbolize_names: true

      if res.is_a?(Array) && res&.first&.[](:IDs)&.[](:MAL)&.include?(possible_queries[index][:mal_id])
        series = res
      end

      index += 1
    end

    fanart_url = nil
    if series.is_a? Array
      fanart = res.first[:Images][:Fanarts].first
      source = fanart[:Source]
      id = fanart[:ID]
      fanart_url = get_fanart_url(id:, source:)
    end

    fanart_url
  end

  private
    def get_fanart_url(id:, source:)
      "#{BASE_URL}Image/#{source}/Fanart/#{id}"
    end
end
