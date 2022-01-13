# frozen_string_literal: true

class CreateGameIds < ActiveRecord::Migration[7.0]
  def change
    create_table :game_ids do |t|
      t.string :name
      t.string :ign
      t.string :icon_url
      t.integer :status, default: 1

      t.timestamps
    end
  end
end
