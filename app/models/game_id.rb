# frozen_string_literal: true

class GameId < ApplicationRecord
  has_one_attached :icon
end
