# frozen_string_literal: true
# typed: true

class AnilistUserStatisticsSyncJob
  include Sidekiq::Job
  sidekiq_options retry: 10

  TAG = "[ANILIST STATS SYNC] ".yellow

  def perform
    user_id = ENV.fetch("ANILIST_USER_ID")
    response = AniList::Client.execute(AniList::UserStatisticsQuery, user_id:)
    user = response.data.user.to_h.deep_dup

    genres = user["statistics"]["anime"]["genres"]
    user["statistics"]["anime"]["genres"] = genres
                                              .map do |genre|
                                                genre["weightedScore"] = (genre["meanScore"].to_f * (genre["count"].to_i / (genre["count"].to_i + 10.0))).round(2)
                                                genre
                                              end
                                              .sort_by { |genre| genre["weightedScore"] }.reverse

    studios = user["statistics"]["anime"]["studios"]
    user["statistics"]["anime"]["studios"] = studios
                                               .map do |studio|
                                                 studio["weightedScore"] = (studio["meanScore"].to_f * (studio["count"].to_i / (studio["count"].to_i + 10.0))).round(2)
                                                 studio
                                               end
                                               .sort_by { |studio| studio["weightedScore"] }.reverse

    AnilistUserStatistic.new(user).upsert(replace: true)
    logger.info(TAG + "SYNCING DONE".green)
  end
end
