# frozen_string_literal: true

require "anilist/anilist"

class ApplicationController < ActionController::Base
  include Turbo::Redirection

  class QueryError < StandardError; end

  private
    def query(definition, variables = {})
      response = AniList::Client.query(definition, variables: variables)

      if response.errors.any?
        raise QueryError.new(response.errors[:data].join(", "))
      else
        response.data
      end
    end
end
