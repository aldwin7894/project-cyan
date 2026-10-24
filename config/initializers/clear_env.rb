if Rails.env.production?
  # Erase the master key from memory once it has done its job
  ENV.delete('RAILS_MASTER_KEY')
end
