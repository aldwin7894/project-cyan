# frozen_string_literal: true

class SocialLink
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :url, type: String
  field :class_name, type: String
  field :icon_name, type: String
  field :icon_filename, type: String
  field :icon_url, type: String
  field :status, type: String, default: 1
end
