# frozen_string_literal: true

class HomeController < ApplicationController
  def index; end

  def ping
    render plain: "Welcome to aldwin7894"
  end
end
