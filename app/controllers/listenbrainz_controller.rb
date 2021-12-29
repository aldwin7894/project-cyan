# frozen_string_literal: true

class ListenbrainzController < ApplicationController
  layout "listenbrainz"

  def index
    respond_to do |format|
      format.json { render json: HTTParty.get("https://api.listenbrainz.org/1/user/#{params[:username]}/listens?count=1") }
    end
  end
end
