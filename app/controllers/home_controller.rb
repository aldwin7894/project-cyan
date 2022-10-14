# frozen_string_literal: true

require "spotify/spotify"

class HomeController < ApplicationController
  include FormatDateHelper
  ANIME_FORMATS = ["TV", "TV_SHORT", "ONA"]
  IGNORED_USER_STATUS = ["plans to watch", "paused watching", "dropped"]

  def index
    @game_ids = GameId.where(status: 1).order(id: :asc)
  end

  def anilist_user_statistics
    user_id = ENV.fetch("ANILIST_USER_ID")
    @user_statistics = Rails.cache.fetch("ANILIST_USER_STATS_#{ENV.fetch('ANILIST_USERNAME')}", expires_in: 30.minutes, skip_nil: true) do
      user_statistics = query(AniList::UserStatisticsQuery, user_id:)
      user_statistics.user.statistics.anime.to_h
    end
    colors = ["#ed2626", "#ab2425", "#712625"]

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
      @total_watched_anime_time = format_date(@user_statistics["minutesWatched"].to_i * 60)
      @total_watched_anime_ep = @user_statistics["episodesWatched"].to_i
    when "total_watched_anime_movie"
      @total_watched_anime_movie_time = format_date(@user_statistics["formats"].to_a.select { |x| !ANIME_FORMATS.include? x["format"] }.map { |x| x["minutesWatched"].to_i }.sum * 60)
      @total_watched_anime_movie = @user_statistics["formats"].to_a.select { |x| !ANIME_FORMATS.include? x["format"] }.map { |x| x["count"].to_i }.sum
    end

    render turbo_frame_request_id, layout: false
  end

  def anilist_user_activities
    user_id = ENV.fetch("ANILIST_USER_ID")
    @user_activity = []
    now = Time.zone.now.beginning_of_day
    last_week = (now.beginning_of_day - 1.month).to_i
    page = 1
    loop do
      res = Rails.cache.fetch("#{now.to_i}_#{page}/ANILIST_USER_ACTIVITIES_#{ENV.fetch('ANILIST_USERNAME')}", expires_in: 30.minutes, skip_nil: true) do
        data = query(AniList::UserAnimeActivitiesQuery, date: last_week, user_id:, page:, per_page: 50)
        { data: data.page.activities.to_a.map(&:to_h), has_next_page: data.page.page_info.has_next_page? }
      end

      @user_activity.push(*res[:data])
      if res[:has_next_page] == false
        break
      else
        page += 1
      end
    end

    @user_activity = @user_activity.select { |x| !IGNORED_USER_STATUS.include? x["status"] }

    case turbo_frame_request_id
    when "last_watched"
      @last_watched = @user_activity&.first
    when "last_watched_movie"
      @last_watched_movie = @user_activity.find { |x| x["media"]["format"] == "MOVIE" }
    when "watched_anime"
      @watched_anime = @user_activity.select { |x| ANIME_FORMATS.include? x["media"]["format"] }
    when "watched_movie"
      @watched_movie = @user_activity.select { |x| !ANIME_FORMATS.include? x["media"]["format"] }
    when "total_watched_anime_last_week"
      @total_watched_anime_time_last_week = format_date(@user_activity.map { |x| x["media"]["duration"].to_i }.sum * 60)
      @total_watched_anime_ep_last_week = @user_activity.size
    when "total_watched_anime_movie_last_week"
      @watched_movie = @user_activity.select { |x| !ANIME_FORMATS.include? x["media"]["format"] }
      @total_watched_anime_movie_time_last_week = format_date(@watched_movie.map { |x| x["media"]["duration"].to_i }.sum * 60)
      @total_watched_anime_movie_last_week = @watched_movie.size
    end

    render turbo_frame_request_id, layout: false
  end

  def lastfm_stats
    @album_art = nil
    @lastfm_recent = Rails.cache.fetch("LASTFM_RECENT_TRACKS", expires_in: 30.seconds, skip_nil: true) do
      LASTFM_CLIENT.user.get_recent_tracks(user: ENV.fetch("LASTFM_USERNAME"), limit: 1, extended: 1)
    end
    if @lastfm_recent.is_a? Array
      @lastfm_recent = @lastfm_recent.first
    end

    album_art = @lastfm_recent&.[]("image")&.[](3)&.[]("content")
    if album_art.present? && album_art.exclude?("2a96cbd8b46e442fc41c2b86b821562f")
      @album_art = album_art
    end

    render layout: false
  rescue Lastfm::ApiError
    @album_art = nil
    render layout: false
  end

  def lastfm_top_artists
    @lastfm_top_artists = Rails.cache.fetch("LASTFM_TOP_ARTISTS", expires_in: 1.week, skip_nil: true) do
      LASTFM_CLIENT.user.get_top_artists(user: ENV.fetch("LASTFM_USERNAME"), period: "overall", limit: 12)
    end

    artist_names = @lastfm_top_artists.pluck("name")
    artist_ids = []
    artist_names.each do |name|
      artist_id = Rails.cache.fetch("SPOTIFY_ARTIST_ID_#{name.parameterize(separator: '_')}", expires_in: 1.week, skip_nil: true) do
        Spotify.get_artist_id_by_name(name)
      end
      artist_ids.push(artist_id)
    end
    images = Spotify.get_artists_images(artist_ids.join(","))

    @lastfm_top_artists = @lastfm_top_artists.each_with_index.map do |artist, i|
      artist["image"] = images[i]
      artist
    end

    render layout: false
  end

  def browserconfig; end

  def site; end

  def ping
    render plain: "Welcome to aldwin7894"
  end
end
