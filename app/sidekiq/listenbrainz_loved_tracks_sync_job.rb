# frozen_string_literal: true
# typed: true

require "listenbrainz"

class ListenbrainzLovedTracksSyncJob
  include Sidekiq::Job
  sidekiq_options retry: 5
  sidekiq_retry_in { 30.minutes }

  TAG = "[LISTENBRAINZ FAVORITES SYNC] ".yellow

  def perform(*args)
    offset = T.let(0, T.untyped)
    total = T.let(1, T.untyped)
    loved_tracks = []

    loop do
      break if offset > total

      sleep 30
      client = ListenBrainz::Client.new
      response = client.get_loved_tracks(user: ENV.fetch("LISTENBRAINZ_USERNAME"), offset:)
      total = response[:total]
      loved_tracks.push(*response[:data])

      offset += 1000
    end

    ListenbrainzLovedTrack.destroy_all
    ListenbrainzLovedTrack.create!(loved_tracks)
    logger.info(TAG + "SYNCING DONE".green)
  end
end
