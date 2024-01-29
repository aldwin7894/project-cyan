# frozen_string_literal: true
# typed: true

require "anilist"
require "application_responder"

class ApplicationController < ActionController::Base
  self.responder = ApplicationResponder
  respond_to? :html

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
