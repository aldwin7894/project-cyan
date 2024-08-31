# frozen_string_literal: true

namespace :cache do
  desc "Clear Vite Image Cache"
  task clear_vite: :environment do
    Rails.cache.delete_matched "ASSETS/*"
  end
end
