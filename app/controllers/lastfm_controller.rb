# frozen_string_literal: true

class LastfmController < ApplicationController
  layout "lastfm"

  def index
    @background = params[:bg]
    @foreground = params[:fg]
    @album_art = nil
    @recent = Rails.cache.fetch("LASTFM_RECENT_TRACKS", expires_in: 30.seconds, skip_nil: true) do
      LASTFM_CLIENT.user.get_recent_tracks(user: params[:username], limit: 1, extended: 1)
    end

    if @recent.is_a? Array
      timestamp = @recent.last["date"]["uts"].to_i
      @recent = @recent.first
    else
      timestamp = @recent["date"]["uts"].to_i
    end

    album_art = @recent&.[]("image")&.[](3)&.[]("content")
    if album_art.present? && album_art.exclude?("2a96cbd8b46e442fc41c2b86b821562f")
      @album_art = album_art
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
    @album_art = nil

    respond_to do |format|
      format.svg
    end
  end
end
