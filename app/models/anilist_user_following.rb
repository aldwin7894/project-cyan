# frozen_string_literal: true

class AnilistUserFollowing
  include Mongoid::Document

  belongs_to :anilist_user, class_name: "AnilistUser"

  field :username, type: String

  index({ anilist_user_id: 1, username: 1 }, { unique: true, name: "anilist_user_following_index" })
end

AnilistUserFollowing.create_indexes
