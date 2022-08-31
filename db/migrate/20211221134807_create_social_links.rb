# frozen_string_literal: true

class CreateSocialLinks < ActiveRecord::Migration[7.0]
  def change
    create_table :social_links do |t|
      t.string :name
      t.string :url
      t.string :class
      t.string :icon_name
      t.string :icon_filename
      t.string :icon_url
      t.integer :status, default: 1

      t.timestamps
    end
  end
end
