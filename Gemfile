# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.4.4"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem "rails", "~> 8.0.2"
# use vite to build javascripts and assets
gem "vite_rails", "~> 3.0"
# Use mongodb
gem "mongoid", "~> 9.0.6"
gem "bson", "~> 5.0"
# Use Puma as the app server
gem "puma", "~> 6.6"
# Turbo gives you the speed of a single-page web application without having to write any JavaScript.
gem "turbo-rails", "~> 2.0.16"
# Use Redis adapter to run Action Cable in production
gem "redis", "~> 5.4"
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.4.4", require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug"
  gem "dotenv", "~> 3.1.8"
  gem "debug"
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  # gem 'web-console', '>= 4.1.0'
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem "rack-mini-profiler", "~> 4.0"
  gem "listen", "~> 3.8"
  gem "rubocop"
  gem "rubocop-rails"
  gem "rubocop-performance"
  gem "rubocop-packaging"
  gem "erb-formatter"
  gem "ruby-lsp", require: false
  gem "ruby-lsp-rails"
  gem "sorbet"
  gem "tapioca", require: false
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem "capybara", ">= 3.26"
  gem "selenium-webdriver"
  # Easy installation and use of web drivers to run system tests with browsers
  gem "webdrivers", "=5.3.0"
end

gem "httparty", "~> 0.23.1"

gem "devise", "~> 4.9"

gem "graphql", "~> 2.0.27"

gem "graphlient", "~> 0.8.0"

gem "lograge", "~> 0.14.0"

gem "rack-brotli", "~> 2.0"

gem "rack", "~> 3"

gem "health_check", "~> 3.1"

gem "httplog", "~> 1.7"

gem "logstash-event", "~> 1.2"

gem "rack-cors", "~> 3.0", require: "rack/cors"

gem "addressable", "~> 2.8"


gem "jwt", "~> 3.0"

gem "recaptcha", "~> 5.19"

# gem "ferrum", "~> 0.13"

gem "discordrb", "~> 3.5.0"

# gem "opentelemetry-sdk"

# gem "opentelemetry-exporter-otlp"

# gem "opentelemetry-instrumentation-all"

gem "kodachroma", "~> 1.0"

gem "responders", "~> 3.1"

gem "persistent_httparty", "~> 0.1.2"

gem "sorbet-runtime"

gem "brotli", "~> 0.6.0"

gem "sidekiq", "~> 8.0"

gem "sidekiq-cron", "~> 2.3"

gem "colorize", "~> 1.1"

gem "sidekiq-unique-jobs", "~> 8.0"

gem "ostruct", "~> 0.6.0"
