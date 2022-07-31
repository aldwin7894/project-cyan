# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root to: "home#index"

  devise_for :users,
    path: "",
    controllers: {
      sessions: "users/sessions",
      passwords: "users/passwords"
    },
    path_names: {
      sign_in: "/admin/login",
      password: "/admin/forgot",
      sign_out: "/admin/logout"
    }

  resources :lastfm
  resources :anilist
  resources :listenbrainz
  get "ping", to: "home#ping"
  get "anilist_user_activities", to: "home#anilist_user_activities"
  get "anilist_user_statistics", to: "home#anilist_user_statistics"
  get "lastfm_stats", to: "home#lastfm_stats"

  namespace :admin do
    # Redirect /admin to the dashboard page.
    root to: redirect("admin/dashboard")
    resources :dashboard
    resources :users
    resources :social_links, path: "social-links"
  end

  direct :cdn_image do |model, options|
    if model.respond_to?(:signed_id)
      route_for(
        :rails_service_blob_proxy,
        model.signed_id,
        model.filename,
        options.merge(host: ENV["RAILS_ASSET_HOST"])
      )
    else
      signed_blob_id = model.blob.signed_id
      variation_key  = model.variation.key
      filename       = model.blob.filename

      route_for(
        :rails_blob_representation_proxy,
        signed_blob_id,
        variation_key,
        filename,
        options.merge(host: ENV["RAILS_ASSET_HOST"])
      )
    end
  end
end
