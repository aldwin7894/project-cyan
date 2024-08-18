# frozen_string_literal: true

class AnilistUser
  include Mongoid::Document
  include Mongoid::Timestamps

  field :_id, type: Integer
  field :username, type: String
  field :following, type: Array, default: []
  field :followers, type: Array, default: []
  field :last_known_error, type: String, default: nil
  field :sync_in_progress, type: Boolean, default: true
  field :job_id, type: String, default: nil

  index({ _id: 1 }, { unique: true })
end
