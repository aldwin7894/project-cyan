# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch("ASSETS_ALLOWED_ORIGINS").split(" ")
    resource "/vite/*",
      headers: :any,
      methods: [:get, :options, :head]
    resource "/vite/assets/*",
      headers: :any,
      methods: [:get, :options, :head]
  end

  allow do
    origins "*"
    resource "*", headers: :any, methods: [:get, :post, :put, :patch, :options, :head]
  end
end
