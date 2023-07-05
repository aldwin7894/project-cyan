# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  constraints subdomain: "admin" do
    scope module: "admin", as: "admin" do
      # Redirect /admin to the dashboard page.
      root to: redirect("dashboard")
      resources :dashboard
      resources :users
      resources :social_links, path: "social-links"
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

  root to: "home#index"

  get "music-np-banner/lastfm",
    to: "music_np_banner#lastfm",
    constraints: lambda { |req| ["html", "svg"].include? req.format }
  get "music-np-banner/listenbrainz",
    to: "music_np_banner#listenbrainz",
    constraints: lambda { |req| ["html", "svg"].include? req.format }
  resources :anilist, only: [:index, :new] do
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
  get "400", to: "exceptions#index"
  get "403", to: "exceptions#index"
  get "404", to: "exceptions#index"
  get "405", to: "exceptions#index"
  get "406", to: "exceptions#index"
  get "409", to: "exceptions#index"
  get "422", to: "exceptions#index"
  get "500", to: "exceptions#index"
  get "501", to: "exceptions#index"
end
