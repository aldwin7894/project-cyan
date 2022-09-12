# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.1.0"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem "rails", "~> 7.0.4"
# use vite to build javascripts and assets
gem "vite_rails", "~> 3.0"
# Use postgres
gem "pg"
# Use Puma as the app server
gem "puma", "~> 5.6"
# Turbo gives you the speed of a single-page web application without having to write any JavaScript.
gem "turbo-rails", github: "hotwired/turbo-rails", branch: "turbo-7-2-0"
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
  gem "rack-mini-profiler", "~> 3.0"
  gem "listen", "~> 3.7"
  gem "solargraph", "~> 0.46.0"
  gem "solargraph-rails", "~> 0.3.1"
  gem "rubocop", "~> 1.36"
  gem "rubocop-rails", "~> 2.16"
  gem "rubocop-performance", "~> 1.15"
  gem "rubocop-packaging", "~> 0.5.2"
  gem "erb_lint", "~> 0.2.0", require: false
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem "capybara", ">= 3.26"
  gem "selenium-webdriver"
  # Easy installation and use of web drivers to run system tests with browsers
  gem "webdrivers"
end

group :production do
  gem "newrelic_rpm", "~> 8"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem "lastfm", "~> 1.27"

gem "imgkit", "~> 1.6"

gem "devise", "~> 4.8"

gem "aws-sdk-s3", "~> 1"

gem "graphql-client", "~> 0.18.0"

gem "lograge", "~> 0.12.0"

gem "rack-brotli", "~> 1.2"

gem "health_check", "~> 3.1"

gem "httplog", "~> 1.5"

gem "s3_asset_deploy", "~> 1.0"

gem "logstash-event", "~> 1.2"

gem "rack-cors", "~> 1.1", require: "rack/cors"

gem "image_optim_pack", "~> 0.9.1"

gem "image_optim", "~> 0.31.1"

gem "addressable", "~> 2.8"

gem "occson", "~> 4.1"
