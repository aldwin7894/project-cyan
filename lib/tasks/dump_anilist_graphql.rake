# frozen_string_literal: true

require "anilist"

namespace :anilist do
  desc "Update AniList GraphQL schema"
  task dump_anilist_graphql: :environment do
    puts "Dumping Anilist GraphQL Schema ..."
    AniList::Client.schema.dump!
    puts "Anilist GraphQL Schema has been successfully dumped."
  end
end
