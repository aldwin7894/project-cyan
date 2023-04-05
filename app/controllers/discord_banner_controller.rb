# frozen_string_literal: true

require "discordrb"

class DiscordBannerController < ApplicationController
  layout "discord-banner"
  before_action :check_if_from_cloudfront
  before_action :set_no_cache_headers

  FERRUM_OPTIONS = {
    window_size: [600, 126],
    browser_path: "/usr/bin/google-chrome",
    browser_options: {
      'no-sandbox': nil
    },
    timeout: 60,
    pending_connection_errors: false
  }

  DISCORD_BOT = Discordrb::Bot.new(
    token: ENV.fetch("DISCORD_BOT_TOKEN"),
    log_mode: Rails.env.development? ? :debug : :normal,
    intents: :all,
    ignore_bots: true,
    suppress_ready: true
  )
  at_exit { DISCORD_BOT.stop if DISCORD_BOT.connected? }
  DISCORD_BOT.run(true) unless DISCORD_BOT.connected?

  def index
    generate_content(params)
  rescue StandardError => _e
    @large_image = nil
    @icon = nil
  ensure
    respond_to do |format|
      format.png do
        browser = Ferrum::Browser.new(**FERRUM_OPTIONS)
        browser.go_to("#{ENV.fetch('RAILS_HOST')}#{request.fullpath.gsub('.png', '.html')}")
        screenshot = browser.screenshot(format: :png, encoding: :binary)
        browser.quit
        send_data(screenshot, type: "image/png", disposition: :inline)
      end
      format.jpg do
        browser = Ferrum::Browser.new(**FERRUM_OPTIONS)
        browser.go_to("#{ENV.fetch('RAILS_HOST')}#{request.fullpath.gsub('.jpg', '.html')}")
        screenshot = browser.screenshot(format: :jpeg, encoding: :binary, quality: 100)
        browser.quit
        send_data(screenshot, type: "image/jpg", disposition: :inline)
      end
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
    @username = current_user.username
    @username += "##{current_user.discriminator}" if params[:disc] == "true"
    @online_status = current_user.status
    @device = current_user.client_status.keys.first
    @client_status = current_user.client_status.values.first
    @avatar = current_user.avatar_url
    activity = current_user&.activities&.to_a&.first

    if activity.present?
      large_image = activity&.assets&.large_image_url("png")
      icon = ""
      details = "#{activity&.state} - #{activity&.details}"
      subdetails = "#{activity&.assets&.large_text}"
      title = "Playing #{activity&.name}"
      activity_name = activity&.name
      activity_type = activity&.type

      case activity_name
      when "Spotify"
        large_image = "https://i.scdn.co/image/#{activity&.assets&.large_image_url&.split(':')&.last&.split('.')&.first.gsub('b273', '4851')}"
        title = "Listening on Spotify"
      when "Jellyfin"
        title = "Watching on #{activity&.name}"
        large_image = "https://#{large_image.split("https/").last.split(".png").first}?fillWidth=64&quality=80" if large_image.include? "jellyfin."
        details = activity&.details.remove!("Watching").strip
        subdetails = activity&.state
      when "Music"
        title = "Listening to #{activity&.name}"
        details = activity&.details
        subdetails = "#{activity&.state} - #{activity&.assets&.large_text}"
      else
        case activity_type
        when 0
          title = "Playing #{activity&.name}"
        when 1
          title = "Streaming #{activity&.name}"
        when 2
          title = "Listening to #{activity&.name}"
        when 3
          title = "Watching on #{activity&.name}"
        when 4
          title = "Playing #{activity&.name}"
        when 5
          title = "Competing #{activity&.name}"
        end
      end
    end

    @activity = {
      name: activity_name,
      title:,
      details:,
      subdetails:,
      large_image:,
      icon:
    }
  end
end
