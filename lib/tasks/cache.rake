# frozen_string_literal: true

namespace :cache do
  desc "Clear Vite Image Cache"
  task clear_vite: :environment do
    Rails.cache.delete_matched "ASSETS/*"
  end

  desc "Clear Shoko Series Cache"
  task clear_shoko_series: :environment do
    Rails.cache.delete_matched "SHOKO/SERIES/*"
  end

  desc "Clear Shoko Fanart Cache"
  task clear_shoko_fanart: :environment do
    Rails.cache.delete_matched "SHOKO/SERIES/*"
  end
end
