# frozen_string_literal: true

class AnilistUserFollower
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :anilist_user, class_name: "AnilistUser"

  field :username, type: String

  index({ anilist_user_id: 1, username: 1 }, { unique: true, name: "anilist_user_follower_index" })
  index({ updated_at: 1 }, { name: "anilist_user_follower_updated_at_index", expire_after_seconds: 7.days.to_i })
end

AnilistUserFollower.create_indexes
