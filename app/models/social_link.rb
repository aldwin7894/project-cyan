# frozen_string_literal: true

class SocialLink < ApplicationRecord
  has_one_attached :icon
  enum :status, { Inactive: 0, Active: 1 }
end
