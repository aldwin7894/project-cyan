# frozen_string_literal: true

class AnilistUserStatistic
  include Mongoid::Document
  include Mongoid::Timestamps

  field :_id, type: Integer
  field :statistics, type: Hash

  index({ _id: 1 }, { unique: true })
end
