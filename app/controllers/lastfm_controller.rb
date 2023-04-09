# frozen_string_literal: true

require "lastfm/lastfm"

class LastfmController < ApplicationController
  layout "lastfm"
  before_action :check_if_from_cloudfront
  before_action :set_no_cache_headers

  FERRUM_OPTIONS = {
    window_size: [600, 122],
    browser_path: "/usr/bin/google-chrome",
    browser_options: {
      'no-sandbox': nil
    },
    timeout: 60,
    pending_connection_errors: false
  }

  def index
    generate_content(params)
  rescue LastFM::ApiError
    @album_art = nil
  ensure
    respond_to do |format|
      format.png do
        browser = Ferrum::Browser.new(**FERRUM_OPTIONS)
        browser.go_to("#{ENV.fetch('RAILS_HOST')}#{request.fullpath.gsub('.png', '.html')}")
        screenshot = browser.screenshot(format: :png, encoding: :binary)
        browser.quit
        send_data(screenshot, type: "image/png", disposition: :inline)
      end
      format.jpg do
        browser = Ferrum::Browser.new(**FERRUM_OPTIONS)
        browser.go_to("#{ENV.fetch('RAILS_HOST')}#{request.fullpath.gsub('.jpg', '.html')}")
        screenshot = browser.screenshot(format: :jpeg, encoding: :binary, quality: 100)
        browser.quit
        send_data(screenshot, type: "image/jpg", disposition: :inline)
      end
      format.html
      format.svg
    end
  end

  def generate_content(params)
    @background = params[:bg]
    @foreground = params[:fg]
    @bottom_line = params[:line]
    @album_art = nil
    @recent = LastFM.get_recent_tracks(user: ENV.fetch("LASTFM_USERNAME"), limit: 1, extended: 1)

    if @recent.is_a? Array
      timestamp = @recent.last["date"]["uts"].to_i
      @recent = @recent.first
    else
      timestamp = @recent["date"]["uts"].to_i
    end

    album_art = @recent&.[]("image")&.[](2)&.[]("#text")
    if album_art.present? && album_art.exclude?("2a96cbd8b46e442fc41c2b86b821562f")
      @album_art = album_art
    end

    @elapsed_time = Time.zone.at(Time.zone.now - Time.zone.at(timestamp)).utc.strftime "%M:%S"
  end
end
