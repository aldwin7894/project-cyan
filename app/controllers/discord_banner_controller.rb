# frozen_string_literal: true
# typed: true

class DiscordBannerController < ApplicationController
  include DiscordHelper
  layout "discord-banner"
  before_action :check_if_from_cloudfront
  before_action :set_no_cache_headers

  content_security_policy(only: :index) do |policy|
    policy.img_src.reject! { |x| x == :data }
  end unless Rails.env.development?

  # FERRUM_OPTIONS = {
  #   window_size: [600, 126],
  #   browser_path: "/usr/bin/microsoft-edge-beta",
  #   browser_options: {
  #     'no-sandbox': nil,
  #     'no-first-run': nil
  #   },
  #   timeout: 60,
  #   pending_connection_errors: false
  # }

  def index
    generate_content(params)
  rescue StandardError => _e
    @large_image = nil
    @icon = nil
  ensure
    respond_to do |format|
      # format.png do
      #   browser = Ferrum::Browser.new(**FERRUM_OPTIONS)
      #   browser.go_to("#{ENV.fetch('RAILS_HOST')}#{request.fullpath.gsub('.png', '.html')}")
      #   screenshot = browser.screenshot(format: :png, encoding: :binary)
      #   browser.quit
      #   send_data(screenshot, type: "image/png", disposition: :inline)
      # end
      # format.jpg do
      #   browser = Ferrum::Browser.new(**FERRUM_OPTIONS)
      #   browser.go_to("#{ENV.fetch('RAILS_HOST')}#{request.fullpath.gsub('.jpg', '.html')}")
      #   screenshot = browser.screenshot(format: :jpeg, encoding: :binary, quality: 100)
      #   browser.quit
      #   send_data(screenshot, type: "image/jpg", disposition: :inline)
      # end
      format.html
      format.svg
    end
  end

  def generate_content(params)
    require "discord_bot"

    @background = params[:bg]
    @foreground = params[:fg]
    @bottom_line = params[:line]
    @display_username = params[:username] == "true"
    @large_image = nil
    @icon = nil

    current_user = T.let(DiscordBot::BOT.user(ENV.fetch("DISCORD_USER_ID")), Discordrb::User)
    @display_name = current_user.display_name
    @username = current_user.username
    @online_status = current_user.status
    @device = current_user.client_status.keys.first
    @client_status = current_user.client_status.values.first
    @avatar = current_user.avatar_url
    activities = T.let(current_user.activities.to_a, T.nilable(T::Array[Discordrb::Activity]))
    activity = activities&.first

    if activity.present?
      title = "Playing #{activity.name}"
      details = [activity.state, activity.details].compact_blank.join(" - ")
      subdetails = "#{activity.assets&.large_text}"
      large_image = activity.assets&.large_image_url("png")
      icon = ""

      activity_name = activity.name
      activity_type = activity.type
      activity_state = activity.state
      activity_details = activity.details
      activity_assets = T.let(activity.assets, T.nilable(Discordrb::Activity::Assets))

      case activity_name
      when "Spotify"
        large_image = "https://i.scdn.co/image/#{activity_assets&.large_image_url&.split(':')&.last&.split('.')&.first.gsub('b273', '4851')}"
        title = "Listening on Spotify"
      when "Jellyfin"
        title = "Watching on #{activity_name}"
        large_image = get_jellyfin_poster_url(large_image)
        details = activity_state
        subdetails = activity_details.remove!("Watching").strip unless activity_details&.include? "Movie"
      when "Music"
        title = "Listening to #{activity_name}"
        details = activity_details
        subdetails = [activity_state, activity_assets&.large_text].compact_blank.join(" - ")
      else
        case activity_type
        when 0
          title = "Playing #{activity_name || 'Playing a game'}"
          details = details.presence || activity_name
          subdetails = subdetails.presence || get_playing_elapsed_time(activity.timestamps&.start)
        when 1
          title = "Streaming #{activity_name}"
        when 2
          title = "Listening to #{activity_name}"
        when 3
          title = "Watching on #{activity_name}"
        when 4
          title = "Playing #{activity_name}"
        when 5
          title = "Competing #{activity_name}"
        else
          title = "Playing #{activity_name}"
        end
      end
    end

    @activity = {
      name: activity_name,
      title:,
      details:,
      subdetails:,
      large_image:,
      icon:,
      details_width: estimate_text_width(details),
      subdetails_width: estimate_text_width(subdetails),
    }
  end

  def estimate_text_width(text)
    alphanumeric_regex = /[^a-zA-Z0-9_]/i
    symbol_regex = /[^ !@#$%^&*()+=\[\]{};':",.\/<>?-]/i
    alphanumeric = text.gsub(alphanumeric_regex, "")
    symbols = text.gsub(symbol_regex, "")
    non_alphanumeric = text.tr(symbols + alphanumeric, "").length * 14.5
    alphanumeric = alphanumeric.length * 8.91
    symbols = symbols.length * 7.0

    (alphanumeric + symbols + non_alphanumeric).ceil
  end
end
