# frozen_string_literal: true

module DiscordHelper
  def get_jellyfin_poster_url(url)
    return nil unless url.includes("jellyfin.")

    "https://#{large_image.split("https/").last.split(".png").first}?fillWidth=64&quality=80"
  end

  def get_playing_elapsed_time(start_time)
    return nil if start_time.blank?

    "for #{helpers.time_ago_in_words(Time.zone.at(start_time.in_time_zone.to_i)).sub("about", "")}"
  end
end
