# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.2"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem "rails", "~> 7.0.8"
# use vite to build javascripts and assets
gem "vite_rails", "~> 3.0"
# Use mongodb
gem "mongoid", "~> 8.1"
gem "bson", "~> 4.15"
# Use Puma as the app server
gem "puma", "~> 6.4"
# Turbo gives you the speed of a single-page web application without having to write any JavaScript.
gem "turbo-rails", "~> 1.4"
# Use Redis adapter to run Action Cable in production
gem "redis", "~> 5.0"
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.4.4", require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  # gem 'web-console', '>= 4.1.0'
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem "rack-mini-profiler", "~> 3.1"
  gem "listen", "~> 3.8"
  gem "rubocop"
  gem "rubocop-rails"
  gem "rubocop-performance"
  gem "rubocop-packaging"
  gem "erb-formatter"
  gem "ruby-lsp", require: false
  gem "ruby-lsp-rails"
  gem "sorbet"
  gem "sorbet-runtime"
  gem "tapioca", require: false
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem "capybara", ">= 3.26"
  gem "selenium-webdriver"
  # Easy installation and use of web drivers to run system tests with browsers
  gem "webdrivers"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem "httparty", "~> 0.21.0"

gem "devise", "~> 4.9"

gem "graphql", "~> 2.0.27"

gem "graphql-client", "~> 0.18.0"

gem "lograge", "~> 0.13.0"

gem "rack-brotli", "~> 1.2"

gem "health_check", "~> 3.1"

gem "httplog", "~> 1.6"

gem "logstash-event", "~> 1.2"

gem "rack-cors", "~> 2.0", require: "rack/cors"

gem "addressable", "~> 2.8"

gem "occson", "~> 4.2"

gem "jwt", "~> 2.7"

gem "recaptcha", "~> 5.12"

# gem "ferrum", "~> 0.13"

gem "discordrb", "~> 3.5.0"

# gem "opentelemetry-sdk"

# gem "opentelemetry-exporter-otlp"

# gem "opentelemetry-instrumentation-all"

gem "kodachroma", "~> 1.0"

gem "responders", "~> 3.1"

gem "persistent_httparty", "~> 0.1.2"
