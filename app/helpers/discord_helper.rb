# frozen_string_literal: true
# typed: true

module DiscordHelper
  include ActionView::Helpers::DateHelper

  def get_discord_external_asset_url(url:, additional_params: "")
    return url unless url.include?("mp:external")

    "https://#{url.split("https/").last.split(".png").first}#{additional_params}"
  end

  def get_playing_elapsed_time(start_time)
    return nil if start_time.blank?

    "for #{time_ago_in_words(Time.zone.at(start_time.in_time_zone.to_i), include_seconds: true).sub("about", "")}"
  end

  def get_game_icon_url(application_id, game_icon_hash)
    return nil if application_id.blank? || game_icon_hash.blank?

    "https://cdn.discordapp.com/app-icons/#{application_id}/#{game_icon_hash}.png"
  end
end
