if Rails.env.development?
  Rack::MiniProfiler.config.disable_caching = false
end
