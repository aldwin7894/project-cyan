# frozen_string_literal: true
# typed: true

require "anilist"

class AnilistActivitiesSyncJob
  include Sidekiq::Job
  sidekiq_options retry: 5

  TAG = "[ANILIST ACTIVITIES SYNC] ".yellow

  def perform(date = 1704038400, page = 1)
    user_id = ENV.fetch("ANILIST_USER_ID")
    activity_page = AnilistActivity.where(date:, page:)
    current_last_id = activity_page.max(:id)

    response = AniList::Client.execute(AniList::UserAnimeActivitiesQuery, date:, user_id:, page:, per_page: 50)
    has_next_page = response.data&.page&.page_info&.has_next_page? || false
    fetched_last_id = response&.data&.page&.activities&.last&.id

    if current_last_id === fetched_last_id
      logger.info(TAG + "SKIP SYNCING FOR PAGE #{page}".red)
    else
      activity_page.destroy

      response.data.page.activities.to_a.each do |data|
        activity = data.to_h.dup
        activity["date"] = date
        activity["page"] = page

        format = activity&.[]("media")&.[]("format")
        country = activity&.[]("media")&.[]("countryOfOrigin")
        episodes = activity&.[]("media")&.[]("episodes").to_i
        duration = activity&.[]("media")&.[]("duration").to_i

        activity = AnilistActivity.new(activity)

        # Anilist has some weird formatting for ONAs, so we need to fix it
        if format === "ONA"
          if duration <= 10
            activity[:media][:format] = "TV_SHORT"
          elsif country != "CN" && episodes < 10 && duration < 40
            activity[:media][:format] = "OVA"
          elsif episodes === 1 && duration >= 40
            activity[:media][:format] = "MOVIE"
          end
        end

        activity.upsert(replace: true)
      end

      logger.info(TAG + "SYNCING DONE FOR PAGE #{page}".green)
    end

    if has_next_page == true
      self.class.perform_in(5.seconds, date, page + 1)
      logger.info(TAG + "SYNCING FOR PAGE #{page + 1} IS SCHEDULED".green)
    end
  end
end
