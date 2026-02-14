# frozen_string_literal: true
# typed: true

require "anilist"
require "application_responder"

class ApplicationController < ActionController::Base
  self.responder = ApplicationResponder
  respond_to? :html

  def remote_ip
    if request.headers["HTTP_CF_CONNECTING_IP"].present?
      request.headers["HTTP_CF_CONNECTING_IP"].strip
    elsif request.headers["X-Forwarded-For"].present?
      T.let(request.headers["X-Forwarded-For"].split(",").first, String).strip
    else
      request.remote_ip
    end
  end

  private
    def check_if_from_cloudfront
      raise "Operation not possible." if request.headers["HTTP_USER_AGENT"] == "Amazon CloudFront"
    end
    def query(definition, variables = {})
      response = AniList::Client.execute(definition, variables)
      response&.data
    end
    def set_no_cache_headers
      response.set_header("Pragma", "no-cache")
      response.set_header("Expires", "0")
      no_store
    end
end
