# frozen_string_literal: true

class LastfmController < ApplicationController
  def index
    api_key = ENV.fetch("LASTFM_API_KEY", "b584404fd3911b681479e874239988af")
    api_secret = ENV.fetch("LASTFM_API_SECRET", "c5c52b0cb57b53d0ef0301282e58714f")
    lastfm = Lastfm.new(api_key, api_secret)

    @recent = lastfm.user.get_recent_tracks(user: params[:username], limit: 10, extended: 1).first
    @background = params[:bg]
    @foreground = params[:fg]

    respond_to do |format|
      format.jpg do
        kit = IMGKit.new(render_to_string, width: 600, height: 122, quality: 100, encoding: "utf-8")
        send_data(kit.to_jpg, type: "image/jpg", disposition: :inline)
      end
      format.html
    end
  end
end
