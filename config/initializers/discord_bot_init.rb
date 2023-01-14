# frozen_string_literal: true

require "discordrb"

module PresenceUpdate
  extend Discordrb::EventContainer

  presence do |event|
    Rails.logger.info({
      client_status: event.user.client_status,
      status: event.user.status,
      activities: event.user.activities
    })
  end
end
