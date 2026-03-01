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

  index({ user_id: 1 }, { name: "listenbrainz_loved_tracks_user_id_index" })
  index({ recording_mbid: 1 }, { name: "listenbrainz_loved_tracks_recording_mbid_index", sparse: true })
  index({ recording_msid: 1 }, { name: "listenbrainz_loved_tracks_recording_msid_index", sparse: true })
end

ListenbrainzLovedTrack.create_indexes
