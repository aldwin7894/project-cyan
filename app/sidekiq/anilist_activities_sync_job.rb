# frozen_string_literal: true
# typed: true

require "anilist"

class AnilistActivitiesSyncJob
  include Sidekiq::Job
  sidekiq_options retry: 5
  sidekiq_retry_in { 30.minutes }

  def perform(date = 1704038400, page = 1)
    user_id = ENV.fetch("ANILIST_USER_ID")

    response = AniList::Client.execute(AniList::UserAnimeActivitiesQuery, date:, user_id:, page:, per_page: 50)
    has_next_page = response.data&.page&.page_info&.has_next_page? || false
    activities = response.data.page.activities.to_a.map do |data|
      activity = data.to_h.dup
      activity["date"] = date
      activity["page"] = page

      activity
    end

    AnilistActivity.where(date:, page:).destroy
    AnilistActivity.create(activities)

    if has_next_page == true
      self.class.perform_in(Rails.env.development? ? 20.seconds : 60.seconds, date, page + 1)
    end
  end
end
