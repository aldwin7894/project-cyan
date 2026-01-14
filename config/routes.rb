# frozen_string_literal: true

require "sidekiq/web"
require "sidekiq/cron/web"

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  constraints subdomain: "admin" do
    scope module: "admin", as: "admin" do
      # Redirect /admin to the dashboard page.
      root to: redirect("dashboard")
      resources :dashboard
      resources :users
      resources :game_ids, path: "game-ids"
    end

    devise_for :users,
      path: "",
      controllers: {
        sessions: "users/sessions",
        passwords: "users/passwords"
      },
      path_names: {
        sign_in: "/login",
        password: "/forgot",
        sign_out: "/logout"
      }

    end
    mount Sidekiq::Web => "/sidekiq"

  root to: "home#index"

  get "music-np-banner/lastfm",
    to: "music_np_banner#lastfm",
    constraints: lambda { |req| ["html", "svg"].include? req.format }
  get "music-np-banner/listenbrainz",
    to: "music_np_banner#listenbrainz",
    constraints: lambda { |req| ["html", "svg"].include? req.format }
  resources :anilist, only: [:index, :new, :show] do
    collection do
      get "fetch_followers"
    end
  end
  resources :discord_banner,
    path: "discord-banner",
    only: :index,
    constraints: lambda { |req| ["html", "svg"].include? req.format }
  get "ping", to: "home#ping"
  get "anilist_user_activities", to: "home#anilist_user_activities"
  get "anilist_user_statistics", to: "home#anilist_user_statistics"
  get "watched_anime_section", to: "home#watched_anime_section"
  get "watched_movie_section", to: "home#watched_movie_section"
  get "lastfm_stats", to: "home#lastfm_stats"
  get "lastfm_top_artists", to: "home#lastfm_top_artists"
  get "browserconfig", to: "home#browserconfig", constraints: lambda { |req| req.format == :xml }, as: "browserconfig"
  get "site", to: "home#site", constraints: lambda { |req| req.format == :webmanifest }, as: "webmanifest"

  # error pages
  %w(400 403 404 405 406 409 422 500 501).each do |code|
    get code, to: "exceptions#index", defaults: { code: }
  end
end
