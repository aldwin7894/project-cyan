# frozen_string_literal: true

require "discordrb"
require "discord_bot/presence_update"

module DiscordBot
  BOT = Discordrb::Bot.new(token: ENV.fetch("DISCORD_BOT_TOKEN"), log_mode: :verbose, intents: :all)

  def DiscordBot.initialize
    BOT.include! PresenceUpdate
    at_exit { BOT.stop }
    BOT.run(true)
  end
end
