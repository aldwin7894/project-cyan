# frozen_string_literal: true

require "graphql/client"
require "graphql/client/http"

namespace :anilist do
  desc "Update AniList GraphQL schema"
  task dump_anilist_graphql: :environment do
    filename = Rails.root.join("db/schema.json").to_s

    puts "Dumping Anilist GraphQL Schema ..."
    GraphQL::Client.dump_schema(GraphQL::Client::HTTP.new("https://graphql.anilist.co"), filename)
    puts "Anilist GraphQL Schema has been successfully dumped."
  end
end
