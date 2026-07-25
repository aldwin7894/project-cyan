Rails.application.config.after_initialize do
  if defined?(Rails::Server)
    require "discord_bot/discord_bot"
  end
end
