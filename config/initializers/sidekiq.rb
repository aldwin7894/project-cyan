# frozen_string_literal: true
# typed: true

require "sidekiq-unique-jobs"

url = ENV.fetch("REDIS_URL", "redis://localhost:6379/1")
Sidekiq.configure_server do |config|
  config.redis = { url: }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
  end

  SidekiqUniqueJobs::Server.configure(config)
end

Sidekiq.configure_client do |config|
  config.redis = { url: }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end

SidekiqUniqueJobs.configure do |config|
  config.reaper = :none
end
