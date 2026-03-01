# frozen_string_literal: true

class AnilistUserFollower
  include Mongoid::Document

  belongs_to :anilist_user, class_name: "AnilistUser"

  field :username, type: String

  index({ anilist_user_id: 1, username: 1 }, { unique: true, name: "anilist_user_follower_index" })
end

AnilistUserFollower.create_indexes
