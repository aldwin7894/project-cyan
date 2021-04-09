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
  get "ping", to: "home#ping"

  namespace :admin do
    # Redirect /admin to the dashboard page.
    root to: redirect("admin/dashboard")
    resources :dashboard
    resources :users
  end
end
