# frozen_string_literal: true

module DiscordHelper
  def get_discord_external_asset_url(url:, additional_params: "")
    return url unless url.include?("mp:external")

    "https://#{url.split("https/").last.split(".png").first}#{additional_params}"
  end

  def get_playing_elapsed_time(start_time)
    return nil if start_time.blank?

    "for #{helpers.time_ago_in_words(Time.zone.at(start_time.in_time_zone.to_i)).sub("about", "")}"
  end
end
