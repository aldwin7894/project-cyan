# frozen_string_literal: true

class SpotifyArtistWhitelist
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :spotify_id, type: String

  index({ spotify_id: 1 }, { unique: true })
end
