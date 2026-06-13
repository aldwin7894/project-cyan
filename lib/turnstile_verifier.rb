# frozen_string_literal: true

# lib/turnstile_verifier.rb
class TurnstileVerifier
  BASE_URL = "https://challenges.cloudflare.com"
  MAX_RETRIES = 3
  JSON_HEADER = {
    "Accept": "application/json",
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
    persistent_connection_adapter name: "turnstile_verifier",
      pool_size: 2,
      idle_timeout: 10,
      keep_alive: 30
    base_uri BASE_URL + "/turnstile/v0"

    attr_reader :token, :ip

    def initialize(token, ip)
      @options = {
        headers: {
          **JSON_HEADER
        },
        timeout: 10,
        format: :plain
      }
      @token = token
      @ip = ip
    end

    def verify
      return false if token.blank?

      url = "/siteverify"
      log_tag = "TurnstileVerifier.verify".yellow

      MAX_RETRIES.times do |attempt|
        response = self.class.post(
          url,
          body: {
            secret: ENV.fetch("CF_TURNSTILE_SECRET_KEY"),
            response: token,
            remoteip: ip
          }.to_json,
          headers: JSON_HEADER
        )
        unless response.success?
          raise ApiError.new(response.body.to_json, response.code)
        end

        response = JSON.parse response.body, symbolize_names: true
        if response[:success]
          Rails.logger.tagged("TURNSTILE".yellow, log_tag) do
            Rails.logger.info "Verification successful".green
          end

          return true
        else
          error_codes = response[:"error-codes"] || []
          raise ApiError.new("Verification failed: #{error_codes.join(", ")}", nil)
        end
      rescue HTTParty::Error, ApiError, JSON::ParserError => e
        Rails.logger.tagged("TURNSTILE".yellow, log_tag) do
          Rails.logger.error "Verification error (attempt #{attempt + 1}/#{MAX_RETRIES}): #{e.message}".red
        end

        sleep(2**attempt) if attempt < MAX_RETRIES - 1
      end
    end

    false
  end
end
