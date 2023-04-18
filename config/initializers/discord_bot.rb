DISCORD_BOT = Discordrb::Bot.new(
  token: ENV.fetch("DISCORD_BOT_TOKEN"),
  log_mode: Rails.env.development? ? :debug : :normal,
  intents: :all,
  ignore_bots: true,
  suppress_ready: true
)
at_exit { DISCORD_BOT.stop if DISCORD_BOT.connected? }
DISCORD_BOT.run(true) unless DISCORD_BOT.connected?
