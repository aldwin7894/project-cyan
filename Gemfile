source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.1.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '~> 7.0.1'
# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails", git: 'https://github.com/rails/sprockets-rails.git'
# Use postgres
gem 'pg'
# Use Puma as the app server
gem 'puma', '~> 5.5'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Transpile app-like JavaScript. Read more: https://github.com/shakacode/shakapacker
gem "shakapacker", "~> 6.0"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.11'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.5'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  # gem 'web-console', '>= 4.1.0'
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem 'rack-mini-profiler', '~> 2.3'
  gem 'listen', '~> 3.7'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 3.26'
  gem 'selenium-webdriver'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'webdrivers'
end

group :production do
  gem "newrelic_rpm", "~> 8"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem "lastfm", "~> 1.27"

gem "rexml", "~> 3.2"

gem "sassc-rails", "~> 2.1"

gem "imgkit", "~> 1.6"

gem "devise", "~> 4.8"

gem "cocoon", "~> 1.2"

gem "aws-sdk-s3", "~> 1"

gem "exception_handler", "~> 0.8.0"

gem "graphql-client", "~> 0.17.0"

gem "lograge", "~> 0.11.2"

gem "rack-brotli", "~> 1.2"

gem "health_check", "~> 3.1"

gem "heroicon", "~> 0.4.0"

gem "fog-aws", "~> 3.12"

gem "asset_sync", "~> 2.15"

gem "terser", "~> 1.1"

gem "httplog", "~> 1.5"

gem "image_optim_pack", "~> 0.8.0"

gem "image_optim_rails", "~> 0.4.3"
