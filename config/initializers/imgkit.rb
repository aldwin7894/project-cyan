# frozen_string_literal: true

IMGKit.configure do |config|
  config.wkhtmltoimage = "/usr/bin/wkhtmltoimage" if Rails.env.development?
end
