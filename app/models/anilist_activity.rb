# frozen_string_literal: true

class AnilistActivity
  include Mongoid::Document

  field :_id, type: Integer
  field :__typename, type: String
  field :media, type: Hash
  field :createdAt, type: Integer
  field :status, type: String
  field :progress, type: String
  field :siteUrl, type: String

  index({ _id: 1 }, { unique: true })
end
