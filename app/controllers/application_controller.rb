# frozen_string_literal: true

require "anilist/anilist"

class ApplicationController < ActionController::Base
  before_action :check_if_from_cloudfront
  class QueryError < StandardError; end

  private
    def check_if_from_cloudfront
      raise "Operation not possible." if request.headers["HTTP_USER_AGENT"] == "Amazon CloudFront"
    end
    def query(definition, variables = {})
      response = AniList::Client.query(definition, variables:)

      if response.errors.any?
        raise QueryError.new(response.errors[:data].join(", "))
      else
        response.data
      end
    end
end
