# frozen_string_literal: true

require_relative "boot"

require "rails/all"
require "occson"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Aldwin7894
  class Application < Rails::Application
    # get env variables from occson
    config.before_configuration do
      source = Rails.env.production? ? "occson://0.1.0/.env.prod" : "occson://0.1.0/.env.dev"
      access_token = ENV.fetch("OCCSON_ACCESS_TOKEN")
      passphrase = ENV.fetch("OCCSON_PASSPHRASE")

      document = Occson::Document.new(source, access_token, passphrase).download

      document&.split("\n")&.each do |line|
        key, value = line.split("=", 2)

        ENV.store(key, value)
      end
    end
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0
    config.time_zone = "Singapore"
    config.active_record.default_timezone = :local
    config.x.feature.lograge = ENV.fetch("LOGRAGE", "false") == "true"
    config.middleware.use Rack::Deflater
    config.middleware.use Rack::Brotli
    config.action_controller.forgery_protection_origin_check = false
    config.session_store :cookie_store, key: "_app_session"

    config.exceptions_app = ->(env) { ExceptionsController.action(:index).call(env) }

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
