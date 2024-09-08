# frozen_string_literal: true
# typed: true

require "spotify"
require "lastfm"
require "shoko"
require "fanart"

class HomeController < ApplicationController
  include FormatDateHelper
  include Turbo::Frames::FrameRequest
  layout "application"
  before_action :check_if_from_cloudfront
  before_action :check_if_turbo_frame, only: %i(lastfm_stats lastfm_top_artists anilist_user_statistics anilist_user_activities watched_anime_section watched_movie_section)

  ANIME_FORMATS = ["TV", "TV_SHORT", "ONA"]
  IGNORED_USER_STATUS = ["plans to watch", "paused watching", "dropped"]
  ANIME_RELATIONS = ["PREQUEL", "SEQUEL", "PARENT", "SIDE_STORY", "ALTERNATIVE"]

  def index
    @game_ids = GameId.where(status: 1).order(id: :asc)
  end

  def anilist_user_statistics
    user_id = ENV.fetch("ANILIST_USER_ID")
    colors = ["#cc333f", "#00a0b0", "#eb6841", "#f6a4b8", "#edc951", "#b3cc57"]
    @user_statistics = AnilistUserStatistic
                         .find(user_id)
                         &.[]("statistics")
                         &.[]("anime") || {}

    case turbo_frame_request_id
    when "favorite_anime_genres"
      # genre stats
      genre_statistics = @user_statistics["genres"]&.sort_by { |genre| genre["count"] }&.reverse!&.first(6)&.map do |genre|
        { name: genre["genre"], count: genre["count"].to_i }
      end
      genre_total_count = genre_statistics&.pluck(:count)&.sum.to_i
      @genre_list = genre_statistics&.map&.with_index do |genre, index|
        percentage = ((genre[:count].to_d / genre_total_count) * 100).ceil

        {
          label: "#{genre[:name]} (#{percentage}%)",
          value: genre[:count],
          backgroundColor: colors[index]
        }
      end
      @genre_chart_data = JSON.generate({
        labels: @genre_list&.pluck(:label) || [],
        datasets: [
          {
            label: "Anime Count",
            data: @genre_list&.pluck(:value) || [],
            backgroundColor: @genre_list&.pluck(:backgroundColor) || [],
            hoverOffset: 4
          }
        ]
      })
    when "favorite_anime_studios"
      # studio stats
      studio_statistics = @user_statistics["studios"]&.sort_by { |genre| genre["count"] }&.reverse!&.first(6)&.map do |studio|
        { name: studio["studio"]["name"], count: studio["count"].to_i }
      end
      studio_total_count = studio_statistics&.pluck(:count)&.sum.to_i
      @studio_list = studio_statistics&.map&.with_index do |studio, index|
        percentage = ((studio[:count].to_d / studio_total_count) * 100).ceil

        {
          label: "#{studio[:name]} (#{percentage}%)",
          value: studio[:count],
          backgroundColor: colors[index]
        }
      end
      @studio_chart_data = JSON.generate({
        labels: @studio_list&.pluck(:label) || [],
        datasets: [
          {
            label: "Anime Count",
            data: @studio_list&.pluck(:value) || [],
            backgroundColor: @studio_list&.pluck(:backgroundColor) || [],
            hoverOffset: 4
          }
        ]
      })
    when "total_watched_anime"
      @total_watched_anime_time_mins = @user_statistics&.[]("minutesWatched").to_i
      @total_watched_anime_time = format_date(@total_watched_anime_time_mins * 60)
      @total_watched_anime_ep = @user_statistics&.[]("episodesWatched").to_i

      statuses = @user_statistics["statuses"].to_a
      @total_completed_anime = statuses.find { |x| x["status"] == "COMPLETED" }&.[]("count").to_i
      @total_planning_anime = statuses.find { |x| x["status"] == "PLANNING" }&.[]("count").to_i
      @total_dropped_anime = statuses.find { |x| x["status"] == "DROPPED" }&.[]("count").to_i
      @total_current_anime = statuses.find { |x| x["status"] == "CURRENT" }&.[]("count").to_i
      @total_paused_anime = statuses.find { |x| x["status"] == "PAUSED" }&.[]("count").to_i
    when "total_watched_anime_movie"
      @total_watched_anime_movie_time_mins = @user_statistics["formats"]
                                               .to_a
                                               .select { |x| ANIME_FORMATS.exclude? x["format"] }
                                               .map { |x| x&.[]("minutesWatched").to_i }.sum
      @total_watched_anime_movie_time = format_date(@total_watched_anime_movie_time_mins * 60)
      @total_watched_anime_movie = @user_statistics["formats"].to_a
                                     .select { |x| ANIME_FORMATS.exclude? x["format"] }
                                     .map { |x| x&.[]("count").to_i }.sum
    else return render nothing: true
    end

    render template: "home/#{turbo_frame_request_id}", layout: false if turbo_frame_request?
  rescue StandardError => error
    render_empty(error)
  end

  def anilist_user_activities
    now = Time.zone.now.beginning_of_day
    last_week_start = (now - 1.week).beginning_of_week.to_i
    last_week_end = (now - 1.week).end_of_week.to_i
    turbo_frame = turbo_frame_request_id

    case turbo_frame_request_id
    when "last_watched"
      last_watched = AnilistActivity
                       .order(id: :desc)
                       .where.in("media.format": ANIME_FORMATS)
                       .and.not.in(status: IGNORED_USER_STATUS)
                       .limit(1)
                       &.first
      @last_watched = user_activity_fetch_fanart(activity: last_watched)
    when "last_watched_movie"
      last_watched_movie = AnilistActivity
                             .order(id: :desc)
                             .where("media.format": "MOVIE")
                             .and.not.in(status: IGNORED_USER_STATUS)
                             .limit(1)
                             &.first
      @last_watched_movie = user_activity_fetch_fanart(activity: last_watched_movie)
    when /watched_anime_\d+_\d+/
      @index = turbo_frame_request_id.scan(/\d+/).first.to_i
      @watched_anime = AnilistActivity
                         .order(id: :desc)
                         .where.in("media.format": ANIME_FORMATS)
                         .and.not.in(status: IGNORED_USER_STATUS)
                         &.each_slice(6)
                         &.to_a
                         &.[](@index)
      turbo_frame = "watched_anime"
    when /watched_movie_\d+_\d+/
      @index = turbo_frame_request_id.scan(/\d+/).first.to_i
      @watched_movie = AnilistActivity
                         .order(id: :desc)
                         .where.not.in("media.format": ANIME_FORMATS)
                         .and.not.in(status: IGNORED_USER_STATUS)
                         &.each_slice(6)
                         &.to_a
                         &.[](@index)
      turbo_frame = "watched_movie"
    when "total_watched_anime_last_week"
      watched_last_week = AnilistActivity
                            .order(id: :desc)
                            .where(createdAt: { "$gte": last_week_start, "$lte": last_week_end })
                            .and.not.in(status: IGNORED_USER_STATUS)
      @total_watched_anime_time_last_week_mins = watched_last_week
                                                   .map { |x| x&.[]("media")&.[]("duration").to_i }
                                                   .sum
      @total_watched_anime_time_last_week = format_date(@total_watched_anime_time_last_week_mins * 60)
      @total_watched_anime_ep_last_week = watched_last_week.size
    when "total_watched_anime_movie_last_week"
      watched_last_week = AnilistActivity
                            .order(id: :desc)
                            .where.not.in("media.format": ANIME_FORMATS)
                            .and(createdAt: { "$gte": last_week_start, "$lte": last_week_end })
                            .and.not.in(status: IGNORED_USER_STATUS)
      @total_watched_anime_movie_time_last_week_mins = watched_last_week
                                                         .map { |x| x&.[]("media")&.[]("duration").to_i }
                                                         .sum
      @total_watched_anime_movie_time_last_week = format_date(@total_watched_anime_movie_time_last_week_mins * 60)
      @total_watched_anime_movie_last_week = watched_last_week.size
    else return render nothing: true
    end

    render template: "home/#{turbo_frame}", layout: false if turbo_frame_request?
  rescue StandardError => error
    render_empty(error)
  end

  def watched_anime_section
    @watched_anime = AnilistActivity
                       .order(id: :desc)
                       .where.in("media.format": ANIME_FORMATS)
                       .and.not.in(status: IGNORED_USER_STATUS)
    render template: "home/#{turbo_frame_request_id}", layout: false if turbo_frame_request?
  rescue StandardError => error
    render_empty(error)
  end

  def watched_movie_section
    @watched_movie = AnilistActivity
                       .order(id: :desc)
                       .where
                       .not.in("media.format": ANIME_FORMATS)
                       .and
                       .not.in(status: IGNORED_USER_STATUS)
    render template: "home/#{turbo_frame_request_id}", layout: false if turbo_frame_request?
  rescue StandardError => error
    render_empty(error)
  end

  def lastfm_stats
    @album_art = nil
    lastfm = LastFM::Client.new
    @lastfm_recent = lastfm.get_recent_tracks(user: ENV.fetch("LASTFM_USERNAME"), limit: 1, extended: 1)

    if @lastfm_recent.is_a? Array
      timestamp = @lastfm_recent.last["date"]["uts"].to_i
      @lastfm_recent = @lastfm_recent.first
    else
      timestamp = @lastfm_recent["date"]["uts"].to_i
    end

    album_art = @lastfm_recent&.[]("image")&.[](3)&.[]("#text")
    if album_art.present? && album_art.exclude?("2a96cbd8b46e442fc41c2b86b821562f")
      @album_art = album_art.split("300x300").join("400x400")
    end

    @elapsed_time = Time.zone.at(Time.zone.now - Time.zone.at(timestamp)).utc.strftime "%M:%S"

    render template: "home/lastfm_stats", layout: false if turbo_frame_request?
  rescue LastFM::ApiError
    @album_art = nil
    render template: "home/lastfm_stats", layout: false if turbo_frame_request?
  end

  def lastfm_top_artists
    lastfm = LastFM::Client.new
    spotify = Spotify::Client.new
    @lastfm_top_artists = lastfm.get_top_artists(user: ENV.fetch("LASTFM_USERNAME"), period: "overall", limit: 20)

    artist_names = @lastfm_top_artists.pluck("name")
    artist_ids = []
    artist_names.each do |name|
      artist_id = spotify.get_artist_id_by_name(name:)
      artist_ids.push(artist_id)
    end
    images = spotify.get_artists_images(ids: artist_ids.join(","))

    @lastfm_top_artists = @lastfm_top_artists.each_with_index.map do |artist, i|
      artist["image"] = images[i] || artist["image"].first["#text"]
      artist
    end

    render template: "home/lastfm_top_artists", layout: false if turbo_frame_request?
  rescue LastFM::ApiError
    @lastfm_top_artists = []
    render template: "home/lastfm_top_artists", layout: false if turbo_frame_request?
  end

  def browserconfig
    # browserconfig.xml
  end

  def site
    # site.webmanifest
  end

  def ping
    render plain: "Welcome to project-cyan"
  end

  private
    def render_empty(exception)
      logger.tagged("ERROR", "HomeController", action_name) do
        logger.error(exception)
      end

      respond_to do |format|
        format.html do
          return render template: "home/#{turbo_frame_request_id}", layout: false if turbo_frame_request?
          render nothing: true
        end
      end
    end

    def user_activity_fetch_fanart(activity:)
      return {} if activity.blank?

      user_activity = activity.deep_dup
      name = user_activity["media"]["format"] === "TV" && user_activity["media"]["countryOfOrigin"] != "CN" ?
        user_activity["media"]["title"]["userPreferred"] :
        user_activity["media"]["title"]["english"]
      name ||= user_activity["media"]["title"]["userPreferred"]
      year = user_activity["media"]["seasonYear"]
      mal_id = user_activity["media"]["idMal"]
      alternatives = user_activity["media"]["relations"]["edges"].select do |x|
        ANIME_RELATIONS.include?(x["relationType"]) && ["TV", "ONA"].include?(x["node"]["format"])
      end.map do |x|
        {
          name: x["node"]["title"]["userPreferred"],
          year: x["node"]["seasonYear"],
          mal_id: x["node"]["idMal"]
        }
      end

      shoko = Shoko::Client.new
      series = shoko.find_series(name:, year:, mal_id:, alternatives:)
      fanart_url = shoko.get_fanart_by_series(series:)

      tvdb_id = series&.[](:IDs)&.[](:TvDB)&.first
      tmdb_id = series&.[](:IDs)&.[](:TMDB)&.[](:Movie)&.first
      tmdb_id ||= series&.[](:IDs)&.[](:TMDB)&.[](:Show)&.first

      if fanart_url.blank? && (tvdb_id.present? || tmdb_id.present?)
        fanart = Fanart::Client.new
        fanart_url ||= fanart.get_fanart_by_tmdb_id(tmdb_id:) if tmdb_id.present?
        fanart_url ||= fanart.get_fanart_by_tvdb_id(tvdb_id:) if tvdb_id.present?
      end

      user_activity["media"]["bannerImage"] = fanart_url if fanart_url.present?
      user_activity
    end

    def check_if_turbo_frame
      head(:unprocessable_entity) unless turbo_frame_request?
    end
end
