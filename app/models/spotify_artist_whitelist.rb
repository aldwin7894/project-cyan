# frozen_string_literal: true

class SpotifyArtistWhitelist
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :spotify_id, type: String

  index({ name: 1 }, { name: "spotify_artist_whitelist_name_index" })
end

SpotifyArtistWhitelist.create_indexes
