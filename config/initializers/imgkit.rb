# frozen_string_literal: true

IMGKit.configure do |config|
  config.wkhtmltoimage = "/usr/local/bin/wkhtmltoimage" if Rails.env.development?
end
