# frozen_string_literal: true

class DiscordBannerController < ApplicationController
  layout "discord-banner"

  DISCORD_BOT = Discordrb::Bot.new(
    token: ENV.fetch("DISCORD_BOT_TOKEN"),
    log_mode: Rails.env.development? ? :debug : :normal,
    intents: :all,
    ignore_bots: true,
    suppress_ready: true
  )
  # DISCORD_BOT.include! PresenceUpdate
  at_exit { DISCORD_BOT.stop if DISCORD_BOT.connected? }
  DISCORD_BOT.run(true) unless DISCORD_BOT.connected?

  def index
    generate_content(params)
  rescue StandardError => _e
    @large_image = nil
    @icon = nil
  ensure
    respond_to do |format|
      format.html
      format.svg
    end
  end

  def generate_content(params)
    @background = params[:bg]
    @foreground = params[:fg]
    @bottom_line = params[:line]
    @large_image = nil
    @icon = nil

    current_user = DISCORD_BOT.user(ENV.fetch("DISCORD_USER_ID"))
    activity = current_user&.activities&.to_a&.first
    large_image = activity&.assets&.large_image_url("png")
    icon = ""
    details = "#{activity&.state} - #{activity&.details}" if activity.present?
    subdetails = "#{activity&.assets&.large_text}" if activity.present?

    if activity&.name == "Spotify" && activity&.type == 2
      large_image = "https://i.scdn.co/image/#{activity&.assets&.large_image_url&.split(':')&.last&.split('.')&.first.gsub('b273', '4851')}"
      title = "Listening to Spotify"
    elsif activity&.type == 0 || activity&.type == 4
      if activity&.name == "Jellyfin" && large_image.include?("jellyfin")
        large_image = "https://#{large_image.split("https/").last.split(".jpg").first}?fillWidth=64&quality=80"
        details = "#{activity&.details} - #{activity&.state}"
      end
      title = "Playing #{activity&.name}"
    elsif activity&.type == 1
      title = "Streaming #{activity&.name}"
    elsif activity&.type == 3
      title = "Watching from #{activity&.name}"
    elsif activity&.type == 5
      title = "Competing #{activity&.name}"
    end

    @username = current_user.username
    @username += "##{current_user.discriminator}" if params[:disc] == "true"
    @online_status = current_user.status
    @device = current_user.client_status.keys.first
    @client_status = current_user.client_status.values.first
    @avatar = current_user.avatar_url
    @activity = {
      name: activity&.name,
      title:,
      details:,
      subdetails:,
      large_image:,
      icon:
    }
  end
end
