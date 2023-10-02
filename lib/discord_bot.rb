# frozen_string_literal: true
# typed: true

require "discordrb"

module DiscordBot
  BOT = Discordrb::Bot.new(
    token: ENV.fetch("DISCORD_BOT_TOKEN"),
    log_mode: Rails.env.development? ? :debug : :normal,
    intents: :all,
    ignore_bots: true,
    suppress_ready: true
  )
  at_exit { BOT.stop if BOT.connected? }
  BOT.run(true) unless BOT.connected?
end
