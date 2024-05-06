# frozen_string_literal: true

require_relative "boot"

require "rails"
require "action_controller/railtie" rescue LoadError
require "action_view/railtie" rescue LoadError
require "action_mailer/railtie" rescue LoadError
require "active_job/railtie" rescue LoadError
require "action_cable/engine" rescue LoadError
require "rails/test_unit/railtie" rescue LoadError

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Aldwin7894
  class Application < Rails::Application
    # Use the responders controller from the responders gem
    config.app_generators.scaffold_controller :responders_controller

    # get env variables from credentials
    config.before_configuration do
      Rails.application.credentials.config.each do |key, value|
        ENV.store(key.to_s, value.to_s)
      end
    end
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0
    config.time_zone = "Singapore"
    config.x.feature.lograge = Rails.application.credentials.config.dig(:LOGRAGE) == "true"
    config.middleware.use Rack::Deflater
    config.middleware.use Rack::Brotli
    config.action_controller.forgery_protection_origin_check = false
    config.session_store :cookie_store, key: "_app_session"
    config.action_view.form_with_generates_remote_forms = false
    config.mongoid.logger = Logger.new(STDERR, :warn)

    config.generators do |g|
      g.orm :mongoid
    end

    config.exceptions_app = self.routes

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
