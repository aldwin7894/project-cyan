# frozen_string_literal: true
# typed: true

require "brotli"
require "digest"
require "sorbet-runtime"
require "securerandom"

module Subsonic
  USERNAME = ENV.fetch("SUBSONIC_USERNAME")
  PASSWORD = ENV.fetch("SUBSONIC_PASSWORD")
  BASE_URL = ENV.fetch("SUBSONIC_BASE_URL")
  VERSION = "1.16.1"
  CLIENT = "project-cyan"
  FORMAT = "json"
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
    persistent_connection_adapter name: "subsonic",
      pool_size: 2,
      idle_timeout: 10,
      keep_alive: 30
    base_uri BASE_URL + "/rest"

    def initialize
      @options = {
        headers: {
          **JSON_HEADER
        },
        timeout: 10,
        format: :plain
      }
    end

    def get_artist_image(name:)
      url = "/search3.view"
      artist_image = T.let(nil, T.nilable(T::Array[T.untyped]))
      log_tag = "Subsonic.get_artist_image".yellow

      cache_key = "SUBSONIC/ARTIST/#{name.downcase.gsub(/\s/, "_")}"
      if Rails.cache.exist? cache_key
        Rails.logger.tagged("CACHE".yellow, log_tag, cache_key.yellow) do
          Rails.logger.info("HIT".green)
        end
        return Rails.cache.fetch(cache_key)
      end

      Rails.logger.tagged("CACHE".yellow, log_tag, cache_key.yellow) do
        Rails.logger.info("MISS".red)
      end

      salt = SecureRandom.hex(3)
      query = {
        u: USERNAME,
        v: VERSION,
        t: Digest::MD5.hexdigest(PASSWORD + salt),
        s: salt,
        c: CLIENT,
        f: FORMAT,
        query: name,
        artistCount: 1,
        albumCount: 0,
        songCount: 0
      }

      Rails.logger.tagged("SUBSONIC".yellow, log_tag, name.yellow) do
        Rails.logger.info("START".green)
      end

      res = self.class.get(url, query:, **@options)
      unless res.success?
        raise ApiError.new(res.body.to_json, res.code)
      end

      res = JSON.parse res.body, symbolize_names: true
      artists = res&.[](:"subsonic-response")&.[](:searchResult3)&.[](:artist) || []
      if artists.is_a?(Array) && !artists.empty?
        artist_image = artists.first[:artistImageUrl]&.sub(BASE_URL, ENV.fetch("ASSETS_BASE_URL"))&.sub("size=600", "size=300")
      else
        Rails.logger.tagged("SUBSONIC".yellow, log_tag, name.yellow) do
          Rails.logger.info("NOT FOUND".red)
        end
      end

      return artist_image if artist_image.blank?

      Rails.cache.write(cache_key, artist_image, expires_in: 3.months)
      artist_image
    rescue HTTParty::Error, ApiError, JSON::ParserError => e
      Rails.logger.tagged("SUBSONIC".yellow, log_tag, name.yellow) do
        Rails.logger.error("ERROR".red, e.message)
      end

      nil
    end
  end
end
