# frozen_string_literal: true
# typed: true

require "anilist"

class AnilistActivitiesSyncJob
  include Sidekiq::Job
  IGNORED_USER_STATUS = ["plans to watch", "paused watching", "dropped"]

  def perform(date)
    user_id = ENV.fetch("ANILIST_USER_ID")
    user_activity = []
    page = 1

    loop do
      response = AniList::Client.execute(AniList::UserAnimeActivitiesQuery, date:, user_id:, page:, per_page: 50)
      has_next_page = response.data&.page&.page_info&.has_next_page? || false

      user_activity.push(*response.data.page.activities.to_a.map(&:to_h))

      break if has_next_page == false

      sleep 20
      page += 1
    end

    user_activity = user_activity.reverse.select { |x| IGNORED_USER_STATUS.exclude? x["status"] }
    user_activity.each do |activity|
      activity = AnilistActivity.new(activity)
      activity.upsert(replace: false)
    end
  end
end
