# frozen_string_literal: true

class LastfmController < ApplicationController
  layout "lastfm"

  def index
    @background = params[:bg]
    @foreground = params[:fg]
    @recent = Rails.cache.fetch("LASTFM_RECENT_TRACKS", expires_in: 30.seconds) do
      LASTFM_CLIENT.user.get_recent_tracks(user: params[:username], limit: 1, extended: 1)
    end

    if @recent.is_a? Array
      timestamp = @recent.last["date"]["uts"].to_i
      @recent = @recent.first
    else
      timestamp = @recent["date"]["uts"].to_i
    end

    album_art = @recent&.[]("image")&.[](2)&.[]("content")

    if album_art.present? && album_art.exclude?("2a96cbd8b46e442fc41c2b86b821562f")
      img = Rails.cache.fetch(album_art, expires_in: 12.hours) do
        HTTParty.get(album_art)
      end
      base64 = Base64.encode64(img.to_s).gsub(/\s+/, "")
      @album_art = "data:image/#{File.extname(album_art).strip.downcase[1..-1]};base64,#{Rack::Utils.escape(base64)}"
    else
      @album_art = helpers.asset_data_uri "lastfm-placeholder.webp"
    end

    @elapsed_time = Time.zone.at(Time.zone.now - Time.zone.at(timestamp)).utc.strftime "%M:%S"

    respond_to do |format|
      format.png do
        kit = IMGKit.new(
          render_to_string,
          width: 600,
          height: 122,
          quality: 60,
          encoding: "utf-8",
          images: true,
          cache_dir: Rails.root.join("assets/images/cache")
        )

        send_data(kit.to_png, type: "image/png", disposition: :inline)
      end
      format.html
      format.svg
    end
  rescue Lastfm::ApiError
    @album_art = helpers.asset_data_uri "lastfm-placeholder.webp"

    respond_to do |format|
      format.svg
    end
  end
end
