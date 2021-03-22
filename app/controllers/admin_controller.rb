# frozen_string_literal: true

class AdminController < ApplicationController
  layout "admin"

  before_action :check_and_authenticate_user
  before_action :authenticate_user!

  private
    def check_and_authenticate_user
      session[:return_to] = request.url
      redirect_to new_user_session_path unless user_signed_in?
    end
end
