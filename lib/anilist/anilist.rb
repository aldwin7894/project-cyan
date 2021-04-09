# frozen_string_literal: true

require "graphql/client"
require "graphql/client/http"

module AniList
  Http ||= GraphQL::Client::HTTP.new("https://graphql.anilist.co")

  # Fetch latest schema on init, this will make a network request
  Schema ||= GraphQL::Client.load_schema(Dir[File.join(Rails.root, "db", "schema.json")][0])

  Client ||= GraphQL::Client.new(schema: Schema, execute: Http)
end
