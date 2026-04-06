# frozen_string_literal: true
# typed: true

require "listenbrainz"

class ListenbrainzLovedTracksSyncJob
  include Sidekiq::Job
  sidekiq_options retry: 10

  TAG = "[LISTENBRAINZ FAVORITES SYNC] ".yellow

  def perform(*_args)
    offset = T.let(0, T.untyped)
    total = T.let(1, T.untyped)
    loved_tracks = []

    loop do
      break if offset > total

      client = ListenBrainz::Client.new
      response = client.get_loved_tracks(user: ENV.fetch("LISTENBRAINZ_USERNAME"), offset:)
      total = response[:total]
      loved_tracks.push(*response[:data])

      offset += 1000
      response[:ratelimit_remaining] < 5 ? sleep(10) : sleep(0.5)
    end

    ListenbrainzLovedTrack.destroy_all
    ListenbrainzLovedTrack.create!(loved_tracks)
    logger.info(TAG + "SYNCING DONE".green)
  end
end
