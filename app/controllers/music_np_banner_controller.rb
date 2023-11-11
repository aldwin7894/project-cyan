# frozen_string_literal: true
# typed: true

require "lastfm"
require "listenbrainz"
require "spotify"

class MusicNpBannerController < ApplicationController
  before_action :check_if_from_cloudfront
  before_action :set_no_cache_headers

  content_security_policy(only: %i(lastfm listenbrainz)) do |policy|
    policy.img_src.reject! { |x| x == :data }
  end unless Rails.env.development?

  # FERRUM_OPTIONS = {
  #   window_size: [600, 122],
  #   browser_path: "/usr/bin/microsoft-edge-beta",
  #   browser_options: {
  #     'no-sandbox': nil,
  #     'no-first-run': nil
  #   },
  #   timeout: 60,
  #   pending_connection_errors: false
  # }

  def lastfm
    generate_lastfm_content(params)
  rescue LastFM::ApiError
    @album_art = nil
  ensure
    respond_to do |format|
      # format.png do
      #   browser = Ferrum::Browser.new(**FERRUM_OPTIONS)
      #   browser.go_to("#{ENV.fetch('RAILS_HOST')}#{request.fullpath.gsub('.png', '.html')}")
      #   screenshot = browser.screenshot(format: :png, encoding: :binary)
      #   browser.quit
      #   send_data(screenshot, type: "image/png", disposition: :inline)
      # end
      # format.jpg do
      #   browser = Ferrum::Browser.new(**FERRUM_OPTIONS)
      #   browser.go_to("#{ENV.fetch('RAILS_HOST')}#{request.fullpath.gsub('.jpg', '.html')}")
      #   screenshot = browser.screenshot(format: :jpeg, encoding: :binary, quality: 100)
      #   browser.quit
      #   send_data(screenshot, type: "image/jpg", disposition: :inline)
      # end
      format.html { render layout: "music-np-banner" }
      format.svg
    end
  end

  def generate_lastfm_content(params)
    @background = params[:bg]
    @foreground = params[:fg]
    @bottom_line = params[:line]
    @album_art = nil

    lastfm = LastFM::Client.new
    @recent = lastfm.get_recent_tracks(user: ENV.fetch("LASTFM_USERNAME"), limit: 1, extended: 1)

    if @recent.is_a? Array
      timestamp = @recent.last["date"]["uts"].to_i
      @recent = @recent.first
    else
      timestamp = @recent["date"]["uts"].to_i
    end

    @album_art = LastFM.get_cover_art_url(@recent)
    @elapsed_time = Time.zone.at(Time.zone.now - Time.zone.at(timestamp)).utc.strftime "%M:%S"
  end

  def listenbrainz
    generate_listenbrainz_content(params)
  rescue ListenBrainz::ApiError
    @album_art = nil
  ensure
    respond_to do |format|
      # format.png do
      #   browser = Ferrum::Browser.new(**FERRUM_OPTIONS)
      #   browser.go_to("#{ENV.fetch('RAILS_HOST')}#{request.fullpath.gsub('.png', '.html')}")
      #   screenshot = browser.screenshot(format: :png, encoding: :binary)
      #   browser.quit
      #   send_data(screenshot, type: "image/png", disposition: :inline)
      # end
      # format.jpg do
      #   browser = Ferrum::Browser.new(**FERRUM_OPTIONS)
      #   browser.go_to("#{ENV.fetch('RAILS_HOST')}#{request.fullpath.gsub('.jpg', '.html')}")
      #   screenshot = browser.screenshot(format: :jpeg, encoding: :binary, quality: 100)
      #   browser.quit
      #   send_data(screenshot, type: "image/jpg", disposition: :inline)
      # end
      format.html { render layout: "music-np-banner" }
      format.svg
    end
  end

  def generate_listenbrainz_content(params)
    @background = params[:bg]
    @foreground = params[:fg]
    @bottom_line = params[:line]
    @album_art = nil

    listenbrainz = ListenBrainz::Client.new
    spotify = Spotify::Client.new
    now_playing = listenbrainz.get_now_playing(user: ENV.fetch("LISTENBRAINZ_USERNAME"))
    loved_tracks = listenbrainz.get_loved_tracks(user: ENV.fetch("LISTENBRAINZ_USERNAME"))

    if now_playing["listens"].blank?
      recent = listenbrainz.get_recent_tracks(user: ENV.fetch("LISTENBRAINZ_USERNAME"), limit: 1)
      @recent = recent["listens"].first
    else
      @recent = now_playing["listens"].first
    end

    release_mbid = @recent&.[]("track_metadata")&.[]("additional_info")&.[]("release_mbid")
    release_mbid ||= @recent&.[]("track_metadata")&.[]("mbid_mapping")&.[]("caa_release_mbid")
    release_mbid ||= @recent&.[]("track_metadata")&.[]("mbid_mapping")&.[]("release_mbid")
    recording_mbid = @recent&.[]("track_metadata")&.[]("additional_info")&.[]("recording_mbid")
    recording_mbid ||= @recent&.[]("track_metadata")&.[]("mbid_mapping")&.[]("recording_mbid")
    spotify_album_id = @recent&.[]("track_metadata")&.[]("additional_info")&.[]("spotify_album_id")

    if release_mbid.present?
      @album_art = ListenBrainz.get_cover_art_url(release_mbid:, size: 250)
    elsif spotify_album_id
      @album_art = spotify.get_album_art(album_id: spotify_album_id&.split("/").pop)
    end
    @loved = loved_tracks.any? { |x| x["recording_mbid"] === recording_mbid.to_s }

    timestamp = @recent["listened_at"].to_i
    @elapsed_time = Time.zone.at(Time.zone.now - Time.zone.at(timestamp)).utc.strftime "%M:%S"
  end
end
