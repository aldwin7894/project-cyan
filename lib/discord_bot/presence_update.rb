# frozen_string_literal: true

require "logger"

module PresenceUpdate
  extend Discordrb::EventContainer

  presence do |event|
    Rails.logger.info(event.inspect)
  end
end
