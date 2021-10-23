# frozen_string_literal: true

class LastfmController < ApplicationController
  layout "lastfm"

  def index
    @recent = LASTFM_CLIENT.user.get_recent_tracks(user: params[:username], limit: 2, extended: 1).first
    @background = params[:bg]
    @foreground = params[:fg]

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
