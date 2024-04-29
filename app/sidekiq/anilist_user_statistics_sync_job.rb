# frozen_string_literal: true
# typed: true

class AnilistUserStatisticsSyncJob
  include Sidekiq::Job
  sidekiq_options retry: 5
  sidekiq_retry_in { 30.minutes }

  def perform
    user_id = ENV.fetch("ANILIST_USER_ID")
    response = AniList::Client.execute(AniList::UserStatisticsQuery, user_id:)

    user_statistics = AnilistUserStatistic.new(response.data.user.to_h)
    user_statistics.upsert(replace: true)
  end
end
