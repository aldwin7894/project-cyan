# frozen_string_literal: true

class DiscordBannerController < ApplicationController
  layout "discord-banner"

  def index
    generate_content(params)
  rescue StandardError
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

    current_user = DiscordBot::BOT.user(ENV.fetch("DISCORD_USER_ID"))
    activity = current_user&.activities&.to_a&.first
    large_image = activity&.assets&.large_image_url("jpg")
    icon = ""
    details = "#{activity&.state} - #{activity&.details}" if activity.present?

    if activity&.name == "Spotify" && activity&.type == 2
      large_image = "https://i.scdn.co/image/#{activity&.assets&.large_image_url&.split(':')&.last&.split('.')&.first}"
      title = "Listening to Spotify"
    elsif activity&.type == 0 || activity&.type == 4
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
      large_image:,
      icon:
    }
  end
end
