# frozen_string_literal: true
# typed: true

require "discordrb"
require "sorbet-runtime"

module DiscordBot
  class DiscordUserActivityTimestamps < T::Struct
    const :start, T.nilable(Time)
    const :end, T.nilable(Time)
  end

  class DiscordUserActivityAssets < T::Struct
    const :large_image_url, T.nilable(String)
    const :large_text, T.nilable(String)
    const :small_image_url, T.nilable(String)
    const :small_text, T.nilable(String)
  end

  class DiscordUserActivity < T::Struct
    const :name, T.nilable(String)
    const :type, Integer
    const :details, T.nilable(String)
    const :state, T.nilable(String)
    const :application_id, T.nilable(String)
    const :timestamps, T.nilable(DiscordUserActivityTimestamps)
    const :assets, T.nilable(DiscordUserActivityAssets)
  end

  class DiscordUser < T::Struct
    const :id, Integer
    const :display_name, String
    const :username, String
    const :online_status, T.nilable(Symbol)
    const :device, T.nilable(Symbol)
    const :client_status, T.nilable(Symbol)
    const :avatar, String
    const :activities, T::Array[DiscordUserActivity]
  end

  USER_ID = ENV.fetch("DISCORD_USER_ID")
  BOT = Discordrb::Bot.new(
    token: ENV.fetch("DISCORD_BOT_TOKEN"),
    log_mode: Rails.env.development? ? :debug : :normal,
    intents: :all,
    ignore_bots: true,
  )
  CACHE_KEY = "DISCORD_BOT/USER_DETAILS/#{USER_ID}"

  class << self
    extend T::Sig

    # Fetch directly from the shared Rails cache
    sig { returns(T.nilable(DiscordUser)) }
    def user_details
      Rails.cache.read(CACHE_KEY)
    end

    # Write directly to the shared Rails cache
    sig { params(user: T.nilable(DiscordUser)).returns(T.nilable(DiscordUser)) }
    def user_details=(user)
      Rails.cache.write(CACHE_KEY, user)
      user
    end

    sig { params(user: Discordrb::User).returns(DiscordUser) }
    def build_discord_user(user)
      client_status_hash = user.client_status || {}
      activities = user.activities.to_a.map do |activity|
        next if activity.name == "Custom Status" && activity.type == 4

        DiscordUserActivity.new(
          name: activity.name,
          type: activity.type,
          details: activity.details,
          state: activity.state,
          application_id: activity.application_id,
          timestamps: DiscordUserActivityTimestamps.new(
            start: activity.timestamps&.start,
            end: activity.timestamps&.end
          ),
          assets: DiscordUserActivityAssets.new(
            large_image_url: activity.assets&.large_image_url("png"),
            large_text: activity.assets&.large_text,
            small_image_url: activity.assets&.small_image_url("png"),
            small_text: activity.assets&.small_text,
          )
        )
      end.compact

      DiscordUser.new(
        id: user.id,
        display_name: user.display_name,
        username: user.username,
        online_status: user.status,
        device: T.let(client_status_hash.keys.first, T.nilable(Symbol)),
        client_status: T.let(client_status_hash.values.first, T.nilable(Symbol)),
        avatar: user.avatar_url.to_s,
        activities:
      )
    end
  end

  BOT.ready do |_event|
    raw_user = BOT.user(USER_ID)
    self.user_details = build_discord_user(raw_user.deep_dup) if raw_user
  end

  BOT.presence do |event|
    next unless event.user.id == USER_ID.to_i

    self.user_details = build_discord_user(event.user.deep_dup)

    Rails.logger.tagged("DiscordBot.presence".yellow) do
      Rails.logger.info("Current user: #{user_details&.username} (#{user_details&.id}), Status: #{user_details&.online_status}, Client Status: #{user_details&.client_status}, Activities: #{user_details&.activities&.map(&:name)&.join(', ')}")
    end
  end

  BOT.playing do |event|
    next unless event.user.id == USER_ID.to_i

    self.user_details = build_discord_user(event.user.deep_dup)

    Rails.logger.tagged("DiscordBot.playing".yellow) do
      Rails.logger.info("Current user: #{user_details&.username} (#{user_details&.id}), Status: #{user_details&.online_status}, Client Status: #{user_details&.client_status}, Activities: #{user_details&.activities&.map(&:name)&.join(', ')}")
    end
  end

  at_exit { BOT.stop if BOT.connected? }
  BOT.run(true) unless BOT.connected?
end
