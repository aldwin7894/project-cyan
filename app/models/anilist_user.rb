# frozen_string_literal: true

class AnilistUser
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :following,
    class_name: "AnilistUserFollowing",
    dependent: :destroy,
    inverse_of: :anilist_user
  has_many :followers,
    class_name: "AnilistUserFollower",
    dependent: :destroy,
    inverse_of: :anilist_user

  field :_id, type: Integer
  field :username, type: String
  field :last_known_error, type: String, default: nil
  field :sync_in_progress, type: Boolean, default: true
  field :job_id, type: String, default: nil

  index({ job_id: 1 }, { name: "anilist_user_job_id_index", sparse: true })
end

AnilistUser.create_indexes
