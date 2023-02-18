# frozen_string_literal: true

class GameId
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :ign, type: String
  field :game_id, type: String
  field :icon_name, type: String
  field :icon_filename, type: String
  field :icon_url, type: String
  field :status, type: Integer, default: 1
end
