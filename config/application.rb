# frozen_string_literal: true

require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Aldwin7894
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0
    config.time_zone = "Singapore"
    config.active_record.default_timezone = :local
    config.x.feature.lograge = ENV.fetch("LOGRAGE", "false") == "true"
    config.middleware.use Rack::Deflater
    config.middleware.use Rack::Brotli

    config.exception_handler = {
      dev:        false, # allows you to turn ExceptionHandler "on" in development
      db:         nil, # allocates a "table name" into which exceptions are saved (defaults to nil)
      email:      nil, # sends exception emails to a listed email (string // "you@email.com")

      exceptions: {
        all: {
          layout: "exception", # define layout
        }
      }
    }

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
