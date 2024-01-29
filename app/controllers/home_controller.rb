# frozen_string_literal: true
# typed: true

require "spotify"
require "lastfm"
require "shoko"

class HomeController < ApplicationController
  include FormatDateHelper
  include Turbo::Frames::FrameRequest
  layout "application"
  rescue_from Graphlient::Errors::Error, with: :render_empty
  rescue_from StandardError, with: :render_empty
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
    now = Time.zone.now
    end_of_day = now.end_of_day
    colors = ["#ed2626", "#ab2425", "#712625"]

    cache_key = "ANILIST/#{ENV.fetch('ANILIST_USERNAME')}/USER_STATS"
    if Rails.cache.exist? cache_key
      logger.tagged("CACHE", "anilist_user_statistics", cache_key) do
        logger.info("HIT")
      end
      @user_statistics = Rails.cache.fetch(cache_key)
    else
      logger.tagged("CACHE", "anilist_user_statistics", cache_key) do
        logger.info("MISS")
      end
      @user_statistics = Rails.cache.fetch(cache_key, expires_in: (end_of_day.to_i - now.to_i).seconds, skip_nil: true) do
        user_statistics = query(AniList::UserStatisticsQuery, user_id:)
        break if user_statistics&.user&.statistics&.anime&.to_h.blank?

        user_statistics.user.statistics.anime.to_h
      end
    end

    case turbo_frame_request_id
    when "favorite_anime_genres"
      # genre stats
      genre_statistics = @user_statistics["genres"].first(6).map do |genre|
        { name: genre["genre"], count: genre["count"].to_i }
      end
      genre_total_count = genre_statistics&.pluck(:count)&.sum.to_i
      @genre_list = genre_statistics.map.with_index do |genre, index|
        percentage = ((genre[:count].to_d / genre_total_count) * 100).ceil

        {
          label: "#{genre[:name]} (#{percentage}%)",
          value: genre[:count],
          backgroundColor: colors[index % 3]
        }
      end
      @genre_chart_data = JSON.generate({
        labels: @genre_list.pluck(:label),
        datasets: [
          {
            label: "Count",
            data: @genre_list.pluck(:value),
            backgroundColor: @genre_list.pluck(:backgroundColor),
            hoverOffset: 4
          }
        ]
      })
    when "favorite_anime_studios"
      # studio stats
      studio_statistics = @user_statistics["studios"].first(6).map do |studio|
        { name: studio["studio"]["name"], count: studio["count"].to_i }
      end
      studio_total_count = studio_statistics&.pluck(:count)&.sum.to_i
      @studio_list = studio_statistics.map.with_index do |studio, index|
        percentage = ((studio[:count].to_d / studio_total_count) * 100).ceil

        {
          label: "#{studio[:name]} (#{percentage}%)",
          value: studio[:count],
          backgroundColor: colors[index % 3]
        }
      end
      @studio_chart_data = JSON.generate({
        labels: @studio_list.pluck(:label),
        datasets: [
          {
            label: "Count",
            data: @studio_list.pluck(:value),
            backgroundColor: @studio_list.pluck(:backgroundColor),
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
  end

  def anilist_user_activities
    now = Time.zone.now.beginning_of_day
    last_week = (now - 1.week).beginning_of_week.to_i
    @user_activity = fetch_anilist_user_activities
    turbo_frame = turbo_frame_request_id

    case turbo_frame_request_id
    when "last_watched"
      last_watched = @user_activity.select { |x| ANIME_FORMATS.include? x["media"]["format"] }&.first
      @last_watched = user_activity_fetch_fanart(activity: last_watched)
    when "last_watched_movie"
      last_watched_movie = @user_activity.find { |x| x["media"]["format"] == "MOVIE" }
      @last_watched_movie = user_activity_fetch_fanart(activity: last_watched_movie)
    when /watched_anime_\d_\d+/
      @index = turbo_frame_request_id.scan(/\d/).first.to_i
      @watched_anime = @user_activity.select { |x| ANIME_FORMATS.include? x["media"]["format"] }&.each_slice(6)&.to_a&.[](@index)
      turbo_frame = "watched_anime"
    when /watched_movie_\d_\d+/
      @index = turbo_frame_request_id.scan(/\d/).first.to_i
      @watched_movie = @user_activity.select { |x| ANIME_FORMATS.exclude? x["media"]["format"] }&.each_slice(6)&.to_a&.[](@index)
      turbo_frame = "watched_movie"
    when "total_watched_anime_last_week"
      @total_watched_anime_time_last_week_mins = @user_activity
                                                   .select { |x| x["createdAt"] >= last_week }
                                                   .map { |x| x&.[]("media")&.[]("duration").to_i }
                                                   .sum
      @total_watched_anime_time_last_week = format_date(@total_watched_anime_time_last_week_mins * 60)
      @total_watched_anime_ep_last_week = @user_activity.select { |x| x["createdAt"] >= last_week }.size
    when "total_watched_anime_movie_last_week"
      @watched_movie = @user_activity.select { |x| ANIME_FORMATS.exclude? x["media"]["format"] }
      @total_watched_anime_movie_time_last_week_mins = @watched_movie
                                                         .select { |x| x["createdAt"] >= last_week }
                                                         .map { |x| x&.[]("media")&.[]("duration").to_i }
                                                         .sum
      @total_watched_anime_movie_time_last_week = format_date(@total_watched_anime_movie_time_last_week_mins * 60)
      @total_watched_anime_movie_last_week = @watched_movie.select { |x| x["createdAt"] >= last_week }.size
    else return render nothing: true
    end

    render template: "home/#{turbo_frame}", layout: false if turbo_frame_request?
  end

  def watched_anime_section
    @user_activity = fetch_anilist_user_activities
    @watched_anime = @user_activity.select { |x| ANIME_FORMATS.include? x["media"]["format"] }
    render template: "home/#{turbo_frame_request_id}", layout: false if turbo_frame_request?
  end

  def watched_movie_section
    @user_activity = fetch_anilist_user_activities
    @watched_movie = @user_activity.select { |x| ANIME_FORMATS.exclude? x["media"]["format"] }
    render template: "home/#{turbo_frame_request_id}", layout: false if turbo_frame_request?
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
      user_activity = activity.deep_dup
      name = user_activity["media"]["format"] == "TV" && user_activity["media"]["countryOfOrigin"] != "CN" ?
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
      fanart = shoko.get_series_fanart_by_name(name:, year:, mal_id:, alternatives:)
      user_activity["media"]["bannerImage"] = fanart if fanart.present?

      user_activity
    end

    def check_if_turbo_frame
      head(:unprocessable_entity) unless turbo_frame_request?
    end

    def fetch_anilist_user_activities
      user_id = ENV.fetch("ANILIST_USER_ID")
      user_activity = []
      now = Time.zone.now.beginning_of_day
      last_month = (now - 1.month).beginning_of_month.to_i
      page = 1

      loop do
        cache_key = "ANILIST/#{ENV.fetch('ANILIST_USERNAME')}/#{last_month.to_i}_#{page}/USER_ACTIVITIES"
        if !Rails.cache.exist? cache_key
          Rails.logger.tagged("CACHE", "anilist_user_activities", cache_key) do
            Rails.logger.info("MISS")
          end
          data = query(AniList::UserAnimeActivitiesQuery, date: last_month, user_id:, page:, per_page: 50)
          has_next_page = data.page.page_info.has_next_page?
          expires_in = has_next_page == false ? 4.hours : 1.week
          res = Rails.cache.fetch(cache_key, expires_in:, skip_nil: true) do
            if data&.page&.activities&.to_a.blank?
              { data: [], has_next_page: false }
            end

            { data: data.page.activities.to_a.map(&:to_h), has_next_page: }
          end
        else
          Rails.logger.tagged("CACHE", "anilist_user_activities", cache_key) do
            Rails.logger.info("HIT")
          end
          res = Rails.cache.fetch(cache_key)
          has_next_page = res[:has_next_page]
        end

        user_activity.push(*res[:data])
        break if has_next_page == false

        page += 1
      end

      user_activity = user_activity.reverse.select { |x| IGNORED_USER_STATUS.exclude? x["status"] }
      user_activity
    end
end
