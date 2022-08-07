require "occson"

source = Rails.env.production? ? "occson://0.1.0/.env.prod" : "occson://0.1.0/.env.dev"
access_token = ENV.fetch("OCCSON_ACCESS_TOKEN")
passphrase = ENV.fetch("OCCSON_PASSPHRASE")

document = Occson::Document.new(source, access_token, passphrase).download

document.split("\n").each do |line|
  key, value = line.split("=", 2)

  ENV.store(key, value)
end
