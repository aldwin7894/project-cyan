# frozen_string_literal: true

class ListenbrainzLovedTrack
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  field :created, type: Integer
  field :recording_mbid, type: String
  field :recording_msid, type: String
  field :score, type: Integer
  field :track_metadata, type: Hash, default: {}
  field :user_id, type: String

  index({ recording_mbid: 1, recording_msid: 1 }, { unique: true })
end
