# frozen_string_literal: true
# typed: true

return unless defined?(Rails::Server)

Rails.application.config.after_initialize do
  require "discord_bot/discord_bot"

  if ENV.fetch("RUN_DISCORD_BOT", "false") == "true" && !DiscordBot::BOT.connected?
    Rails.logger.tagged("discordrb") do
      Rails.logger.info("Starting Discord Bot...".yellow)
    end
    DiscordBot::BOT.run(true)

    at_exit { DiscordBot::BOT.stop if DiscordBot::BOT.connected? }
  end
end
