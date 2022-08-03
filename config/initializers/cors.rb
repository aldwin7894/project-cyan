# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins %w[
      localhost
      aldwin7894.win
      www.aldwin7894.win
    ]
    resource "/vite/*",
      headers: :any,
      methods: :get
    resource "/vite/assets/*",
      headers: :any,
      methods: :get
  end

  allow do
    origins "*"
    resource "*", headers: :any, methods: :get
  end
end
