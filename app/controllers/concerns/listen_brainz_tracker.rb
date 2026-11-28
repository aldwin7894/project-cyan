# frozen_string_literal: true
# typed: true

require "listen_brainz"
require "spotify"

module ListenBrainzTracker
  extend ActiveSupport::Concern

  def fetch_listenbrainz_user_activity(album_art_size: 250)
    listenbrainz = ListenBrainz::Client.new
    spotify = Spotify::Client.new
    listenbrainz_url = "https://listenbrainz.org"
    now_playing = listenbrainz.get_now_playing(user: ENV.fetch("LISTENBRAINZ_USERNAME"))

    if now_playing["listens"].blank?
      recent = listenbrainz.get_recent_tracks(user: ENV.fetch("LISTENBRAINZ_USERNAME"), limit: 1)
      @recent = recent["listens"].first
    else
      @recent = now_playing["listens"].first
      @now_playing = true
    end

    duration = @recent.dig("track_metadata", "additional_info", "duration_ms").to_i
    @duration = format_duration(duration)

    @artist_mbid = @recent&.[]("track_metadata")&.[]("mbid_mapping")&.[]("artist_mbids")&.first
    @artist_mbid ||= @recent&.[]("track_metadata")&.[]("additional_info")&.[]("artist_mbids")&.first
    @artist_url = "#{listenbrainz_url}/artist/#{@artist_mbid}"

    @album_mbid = @recent&.[]("track_metadata")&.[]("mbid_mapping")&.[]("release_mbid")
    @album_mbid = @recent&.[]("track_metadata")&.[]("additional_info")&.[]("release_mbid")
    @album_url = "#{listenbrainz_url}/release/#{@album_mbid}"

    @recording_mbid = @recent&.[]("track_metadata")&.[]("mbid_mapping")&.[]("recording_mbid")
    @recording_mbid ||= @recent&.[]("track_metadata")&.[]("additional_info")&.[]("recording_mbid")

    @recording_msid = @recent&.[]("track_metadata")&.[]("mbid_mapping")&.[]("recording_msid")
    @recording_msid ||= @recent&.[]("track_metadata")&.[]("additional_info")&.[]("recording_msid")

    @recent["url"] = "#{listenbrainz_url}/recording/#{@recording_mbid || @recording_msid}"

    spotify_album_id = @recent&.[]("track_metadata")&.[]("additional_info")&.[]("spotify_album_id")

    if spotify_album_id
      @album_art = spotify.get_album_art(album_id: spotify_album_id&.split("/").pop)
    else
      @album_art = ListenBrainz.get_cover_art_url(track: @recent, size: album_art_size)
    end

    criteria = []
    criteria << { recording_mbid: @recording_mbid } if @recording_mbid.present?
    criteria << { recording_msid: @recording_msid } if @recording_msid.present?
    @loved = ListenbrainzLovedTrack.or(*criteria).exists?

    timestamp = @recent["listened_at"].to_i
    @elapsed_time = Time.zone.at(Time.zone.now - Time.zone.at(timestamp)).utc.strftime "%M:%S"
  end

  private
    def format_duration(ms)
      return nil unless ms && ms > 0

      total_seconds = (ms / 1000.0).round
      minutes, seconds = total_seconds.divmod(60)
      "%d:%02d" % [minutes, seconds]
    end
end
