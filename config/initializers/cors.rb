# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch("ASSETS_ALLOWED_ORIGINS").split(" ")
    resource "/assets/*",
      headers: :any,
      methods: [:get, :post, :options, :head]
    resource "/vite/*",
      headers: :any,
      methods: [:get, :post, :options, :head]
    resource "/vite/assets/*",
      headers: :any,
      methods: [:get, :post, :options, :head]
  end

  allow do
    origins "*"
    resource "/*.png",
      headers: :any,
      methods: [:get, :post, :options, :head]
    resource "/*.ico",
      headers: :any,
      methods: [:get, :post, :options, :head]
    resource "/*.html",
      headers: :any,
      methods: [:get, :post, :options, :head]
    resource "/robots.txt",
      headers: :any,
      methods: [:get, :post, :options, :head]
  end
end
