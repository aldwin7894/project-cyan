# frozen_string_literal: true

require "spotify/spotify"
require "lastfm/lastfm"
require "shoko/shoko"

class HomeController < ApplicationController
  include FormatDateHelper
  layout "application"
  rescue_from QueryError, with: :render_empty
  rescue_from StandardError, with: :render_empty
  before_action :check_if_from_cloudfront

  ANIME_FORMATS = ["TV", "TV_SHORT", "ONA"]
  IGNORED_USER_STATUS = ["plans to watch", "paused watching", "dropped"]

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
        user_statistics.user.statistics.anime.to_h
      end
    end

    case turbo_frame_request_id
    when "favorite_anime_genres"
      # genre stats
      genre_statistics = @user_statistics["genres"].first(6).map do |genre|
        { name: genre["genre"], count: genre["count"].to_i }
      end
      genre_total_count = genre_statistics.pluck(:count).sum
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
            label: "Favorite Genres",
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
      studio_total_count = studio_statistics.pluck(:count).sum
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
            label: "Favorite Studios",
            data: @studio_list.pluck(:value),
            backgroundColor: @studio_list.pluck(:backgroundColor),
            hoverOffset: 4
          }
        ]
      })
    when "total_watched_anime"
      @total_watched_anime_time_mins = @user_statistics["minutesWatched"].to_i
      @total_watched_anime_time = format_date(@total_watched_anime_time_mins * 60)
      @total_watched_anime_ep = @user_statistics["episodesWatched"].to_i

      statuses = @user_statistics["statuses"].to_a
      @total_completed_anime = statuses.find { |x| x["status"] == "COMPLETED" }["count"].to_i
      @total_planning_anime = statuses.find { |x| x["status"] == "PLANNING" }["count"].to_i
      @total_dropped_anime = statuses.find { |x| x["status"] == "DROPPED" }["count"].to_i
      @total_current_anime = statuses.find { |x| x["status"] == "CURRENT" }["count"].to_i
      @total_paused_anime = statuses.find { |x| x["status"] == "PAUSED" }["count"].to_i
    when "total_watched_anime_movie"
      @total_watched_anime_movie_time_mins = @user_statistics["formats"]
                                               .to_a
                                               .select { |x| ANIME_FORMATS.exclude? x["format"] }
                                               .map { |x| x["minutesWatched"].to_i }.sum
      @total_watched_anime_movie_time = format_date(@total_watched_anime_movie_time_mins * 60)
      @total_watched_anime_movie = @user_statistics["formats"].to_a
                                     .select { |x| ANIME_FORMATS.exclude? x["format"] }
                                     .map { |x| x["count"].to_i }.sum
    end

    render turbo_frame_request_id, layout: false
  end

  def anilist_user_activities
    user_id = ENV.fetch("ANILIST_USER_ID")
    @user_activity = []
    now = Time.zone.now.beginning_of_day
    last_week = (now - 1.week).beginning_of_week.to_i
    last_month = (now - 1.month).beginning_of_month.to_i
    page = 1

    # disable querying last page temporarily, until anilist fixes it
    # data = query(AniList::UserAnimeActivitiesLastPageQuery, date: last_month, user_id:, page:, per_page: 50)
    # last_page = data.page.page_info.last_page

    loop do
      cache_key = "ANILIST/#{ENV.fetch('ANILIST_USERNAME')}/#{last_month.to_i}_#{page}/USER_ACTIVITIES"
      if !Rails.cache.exist? cache_key
        logger.tagged("CACHE", "anilist_user_activities", cache_key) do
          logger.info("MISS")
        end
        data = query(AniList::UserAnimeActivitiesQuery, date: last_month, user_id:, page:, per_page: 50)
        has_next_page = data.page.page_info.has_next_page?
        expires_in = has_next_page == false ? 4.hours : 1.week
        res = Rails.cache.fetch(cache_key, expires_in:, skip_nil: true) do
          { data: data.page.activities.to_a.map(&:to_h), has_next_page: }
        end
      else
        logger.tagged("CACHE", "anilist_user_activities", cache_key) do
          logger.info("HIT")
        end
        res = Rails.cache.fetch(cache_key)
        has_next_page = res[:has_next_page]
      end

      @user_activity.push(*res[:data])
      break if has_next_page == false

      page += 1
    end

    @user_activity = @user_activity.reverse.select { |x| IGNORED_USER_STATUS.exclude? x["status"] }

    case turbo_frame_request_id
    when "last_watched"
      last_watched = @user_activity&.first
      @last_watched = user_activity_fetch_fanart(activity: last_watched)
    when "last_watched_movie"
      last_watched_movie = @user_activity.find { |x| x["media"]["format"] == "MOVIE" }
      @last_watched_movie = user_activity_fetch_fanart(activity: last_watched_movie)
    when "watched_anime"
      @watched_anime = @user_activity.select { |x| ANIME_FORMATS.include? x["media"]["format"] }
    when "watched_movie"
      @watched_movie = @user_activity.select { |x| ANIME_FORMATS.exclude? x["media"]["format"] }
    when "total_watched_anime_last_week"
      @total_watched_anime_time_last_week_mins = @user_activity
                                                   .select { |x| x["createdAt"] >= last_week }
                                                   .map { |x| x["media"]["duration"].to_i }
                                                   .sum
      @total_watched_anime_time_last_week = format_date(@total_watched_anime_time_last_week_mins * 60)
      @total_watched_anime_ep_last_week = @user_activity.select { |x| x["createdAt"] >= last_week }.size
    when "total_watched_anime_movie_last_week"
      @watched_movie = @user_activity.select { |x| ANIME_FORMATS.exclude? x["media"]["format"] }
      @total_watched_anime_movie_time_last_week_mins = @watched_movie
                                                         .select { |x| x["createdAt"] >= last_week }
                                                         .map { |x| x["media"]["duration"].to_i }
                                                         .sum
      @total_watched_anime_movie_time_last_week = format_date(@total_watched_anime_movie_time_last_week_mins * 60)
      @total_watched_anime_movie_last_week = @watched_movie.select { |x| x["createdAt"] >= last_week }.size
    end

    render turbo_frame_request_id, layout: false
  end

  def lastfm_stats
    @album_art = nil
    @lastfm_recent = LastFM.get_recent_tracks(user: ENV.fetch("LASTFM_USERNAME"), limit: 1, extended: 1)

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

    render layout: false
  rescue LastFM::ApiError
    @album_art = nil
    render layout: false
  end

  def lastfm_top_artists
    @lastfm_top_artists = LastFM.get_top_artists(user: ENV.fetch("LASTFM_USERNAME"), period: "overall", limit: 12)

    artist_names = @lastfm_top_artists.pluck("name")
    artist_ids = []
    artist_names.each do |name|
      artist_id = Spotify.get_artist_id_by_name(name)
      artist_ids.push(artist_id)
    end
    images = Spotify.get_artists_images(artist_ids.join(","))

    @lastfm_top_artists = @lastfm_top_artists.each_with_index.map do |artist, i|
      artist["image"] = images[i]
      artist
    end

    render layout: false
  rescue LastFM::ApiError
    @lastfm_top_artists = []
    render layout: false
  end

  def browserconfig; end

  def site; end

  def ping
    render plain: "Welcome to project-cyan"
  end

  private
    def render_empty(exception)
      logger.tagged("HomeController", action_name) do
        logger.error(exception)
      end

      respond_to do |format|
        format.html do
          return render turbo_frame_request_id, layout: false if turbo_frame_request?
          render layout: false
        end
      end
    end

    def user_activity_fetch_fanart(activity:)
      user_activity = activity.deep_dup
      name = user_activity["media"]["format"] == "TV" && user_activity["media"]["countryOfOrigin"] != "CN" ?
        user_activity["media"]["title"]["userPreferred"] :
        user_activity["media"]["title"]["english"]
      year = user_activity["media"]["seasonYear"]
      mal_id = user_activity["media"]["idMal"]
      parent = user_activity["media"]["relations"]["nodes"].find { |x| x["format"] == "TV" }
      parent_name = nil
      parent_year = nil
      parent_mal_id = nil
      if parent.present?
        parent_name = parent["title"]["userPreferred"]
        parent_year = parent["seasonYear"]
        parent_mal_id = parent["idMal"]
      end

      fanart = Shoko.get_series_fanart_by_name(name:, year:, mal_id:, parent_name:, parent_year:, parent_mal_id:)
      user_activity["media"]["bannerImage"] = fanart if fanart.present?

      user_activity
    end
end
