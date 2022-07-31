# frozen_string_literal: true

class HomeController < ApplicationController
  include FormatDateHelper
  ANIME_FORMATS = ["TV", "TV Short"]
  IGNORED_USER_STATUS = ["plans to watch", "paused watching", "dropped"]

  def index; end

  def anilist_user_statistics
    user_id = Rails.cache.fetch("ANILIST_USER_ID_#{ENV.fetch('ANILIST_USERNAME')}", expires_in: 1.week, skip_nil: true) do
      query(AniList::UserIdQuery, username: ENV.fetch("ANILIST_USERNAME")).user.id
    end

    user_statistics = query(AniList::UserStatisticsQuery, user_id: user_id)
    @user_statistics = user_statistics.user.statistics.anime

    colors = ["#ed2626", "#ab2425", "#712625"]
    # genre stats
    genre_statistics = @user_statistics.genres.first(6).map do |genre|
      { name: genre.genre, count: genre.count.to_i }
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

    # studio stats
    studio_statistics = @user_statistics.studios.first(6).map do |studio|
      { name: studio.studio.name, count: studio.count.to_i }
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

    # watched stats
    @total_watched_anime_time = format_date(@user_statistics.minutes_watched.to_i * 60)
    @total_watched_anime_ep = @user_statistics.episodes_watched.to_i
    @total_watched_anime_movie_time = format_date(@user_statistics.formats.to_a.select { |x| !ANIME_FORMATS.include? x.format }.map { |x| x.minutes_watched.to_i }.sum * 60)
    @total_watched_anime_movie = @user_statistics.formats.to_a.select { |x| !ANIME_FORMATS.include? x.format }.map { |x| x.count.to_i }.sum

    render layout: false
  end


  def anilist_user_activities
    user_id = Rails.cache.fetch("ANILIST_USER_ID_#{ENV.fetch('ANILIST_USERNAME')}", expires_in: 1.week, skip_nil: true) do
      query(AniList::UserIdQuery, username: ENV.fetch("ANILIST_USERNAME")).user.id
    end

    last_week = (Time.zone.now - 1.week).to_i
    page = 1
    @user_activity = []
    loop do
      data = query(AniList::UserAnimeActivitiesQuery, date: last_week, user_id: user_id, page: page, per_page: 50)
      @user_activity.push(*data.page.activities)

      if data.page.page_info.has_next_page? == false
        break
      else
        page += 1
      end
    end
    @user_activity = @user_activity.select { |x| !IGNORED_USER_STATUS.include? x.status }
    @watched_anime = @user_activity.select { |x| ANIME_FORMATS.include? x.media.format }
    @watched_movie = @user_activity.select { |x| !ANIME_FORMATS.include? x.media.format }
    @total_watched_anime_time_last_week = format_date(@user_activity.map { |x| x.media.duration.to_i }.sum * 60)
    @total_watched_anime_ep_last_week = @user_activity.size
    @total_watched_anime_movie_time_last_week = format_date(@watched_movie.map { |x| x.media.duration.to_i }.sum * 60)
    @total_watched_anime_movie_last_week = @watched_movie.size

    render layout: false
  end

  def lastfm_stats
    # lastfm
    @album_art = helpers.asset_data_uri "lastfm-placeholder.webp"
    @lastfm_recent = Rails.cache.fetch("LASTFM_RECENT_TRACKS", expires_in: 30.seconds, skip_nil: true) do
      LASTFM_CLIENT.user.get_recent_tracks(user: ENV.fetch("LASTFM_USERNAME"), limit: 1, extended: 1)
    end
    if @lastfm_recent.is_a? Array
      @lastfm_recent = @lastfm_recent.first
    end

    album_art = @lastfm_recent&.[]("image")&.[](3)&.[]("content")

    if album_art.present? && album_art.exclude?("2a96cbd8b46e442fc41c2b86b821562f")
      img = Rails.cache.fetch(album_art, expires_in: 7.days, skip_nil: true) do
        HTTParty.get(album_art, format: :plain).body
      end

      if img.present?
        base64 = Base64.strict_encode64(img).gsub(/\s+/, "")
        @album_art = "data:image/#{File.extname(album_art).strip.downcase[1..-1]};base64,#{Rack::Utils.escape(base64)}"
      end
    end

    render layout: false
  end

  def ping
    render plain: "Welcome to aldwin7894"
  end
end
