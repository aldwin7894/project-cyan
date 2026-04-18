# frozen_string_literal: true

class AnilistUserFollowing
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :anilist_user, class_name: "AnilistUser"

  field :username, type: String

  index({ anilist_user_id: 1, username: 1 }, { unique: true, name: "anilist_user_following_index" })
  index({ created_at: 1 }, { name: "anilist_user_following_created_at_index", expire_after_seconds: 7.days.to_i })
end

AnilistUserFollowing.create_indexes
