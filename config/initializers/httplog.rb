# frozen_string_literal: true

HttpLog.configure do |config|
  # Enable or disable all logging
  config.enabled = true

  # You can assign a different logger or method to call on that logger
  config.logger = Logger.new($stdout)
  config.logger_method = :log

  # I really wouldn't change this...
  config.severity = Logger::Severity::INFO

  # Tweak which parts of the HTTP cycle to log...
  # config.log_connect   = true
  # config.log_request   = true
  config.log_headers   = true
  # config.log_data      = true
  # config.log_status    = true
  # config.log_response  = true
  # config.log_benchmark = true

  # ...or log all request as a single line by setting this to `true`
  config.compact_log = true

  # You can also log in JSON format
  config.json_log = true

  # Prettify the output - see below
  config.color = :green

  # Limit logging based on URL patterns
  config.url_whitelist_pattern = /.*/
  config.url_blacklist_pattern = /newrelic|amazonaws|192\.168\./

  # Mask sensitive information in request and response JSON data.
  # Enable global JSON masking by setting the parameter to `/.*/`
  config.url_masked_body_pattern = nil

  # You can specify any custom JSON serializer that implements `load` and `dump` class methods
  # to parse JSON responses
  config.json_parser = JSON

  # When using graylog, you can supply a formatter here - see below for details
  config.graylog_formatter = nil

  # Mask the values of sensitive request parameters
  config.filter_parameters = %w[password api_key apikey authorization]

  # Customize the prefix with a proc or lambda
  config.prefix = -> { "[EXTERNAL] " }
end
