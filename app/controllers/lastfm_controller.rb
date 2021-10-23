# frozen_string_literal: true

class LastfmController < ApplicationController
  layout "lastfm"

  def index
    @recent = LASTFM_CLIENT.user.get_recent_tracks(user: params[:username], limit: 2, extended: 1).first
    @background = params[:bg]
    @foreground = params[:fg]
    if @recent&.[]("image")&.[](3)&.[]("content").present?
      img = HTTParty.get(@recent["image"][3]["content"])
      base64 = Base64.encode64(img.to_s).gsub(/\s+/, "")
      @album_art = "data:image/jpg;base64,#{Rack::Utils.escape(base64)}"
    else
      @album_art = asset_data_uri "lastfm-placeholder.png"
    end

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
  end
end
