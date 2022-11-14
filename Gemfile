# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.1.2"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem "rails", "~> 7.0.4"
# use vite to build javascripts and assets
gem "vite_rails", "~> 3.0"
# Use postgres
gem "pg"
# Use Puma as the app server
gem "puma", "~> 6.0"
# Turbo gives you the speed of a single-page web application without having to write any JavaScript.
gem "turbo-rails", "~> 1.3"
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
  gem "solargraph"
  gem "solargraph-rails"
  gem "rubocop"
  gem "rubocop-rails"
  gem "rubocop-performance"
  gem "rubocop-packaging"
  gem "erb_lint"
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

gem "devise", "~> 4.8"

gem "graphql-client", "~> 0.18.0"

gem "lograge", "~> 0.12.0"

gem "rack-brotli", "~> 1.2"

gem "health_check", "~> 3.1"

gem "httplog", "~> 1.6"

gem "logstash-event", "~> 1.2"

gem "rack-cors", "~> 1.1", require: "rack/cors"

gem "image_optim_pack", "~> 0.9.1"

gem "image_optim", "~> 0.31.1"

gem "addressable", "~> 2.8"

gem "occson", "~> 4.1"

gem "jwt", "~> 2.5"

gem "recaptcha", "~> 5.12"

gem "ferrum", "~> 0.13"
