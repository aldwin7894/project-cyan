# frozen_string_literal: true

module DiscordAPI
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
    base_uri "https://discord.com/api/v10"
    default_timeout 30
    open_timeout 10
    CACHE_TAG = "CACHE".yellow
    DISCORD_API_TAG = "DISCORD API".yellow

    def initialize
      @options = {
        headers: {
          **JSON_HEADER
        },
        timeout: 10,
        format: :plain,
      }
    end

    def get_game_icon_hash(application_id)
      url = "/applications/#{application_id}/rpc"
      cache_key = "DISCORD_API/APPLICATIONS/#{application_id}"
      log_tag = "DiscordAPI.get_game_icon_hash".yellow

      if Rails.cache.exist? cache_key
        Rails.logger.tagged(CACHE_TAG, "DiscordAPI.get_game_icon_hash".yellow, cache_key.yellow) do
          Rails.logger.info("HIT".green)
        end
        return Rails.cache.fetch(cache_key)
      end

      Rails.logger.tagged(CACHE_TAG, log_tag, cache_key.yellow) do
        Rails.logger.info("MISS".red)
      end

      res = self.class.get(url, **@options)
      unless res.success?
        raise ApiError.new(res.body.to_json, res.code)
      end

      res = JSON.parse res.body, symbolize_names: true
      game_icon_hash = res[:icon]

      Rails.cache.write(cache_key, game_icon_hash)
      game_icon_hash
    rescue HTTParty::Error, ApiError, JSON::ParserError => e
      Rails.logger.tagged(DISCORD_API_TAG, log_tag, application_id.to_s.yellow) do
        Rails.logger.error("ERROR: #{e.message}".red)
      end

      nil
    end
  end
end
