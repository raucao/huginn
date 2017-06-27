module Agents
  class StravaActivitiesAgent < Agent
    include StravaConcern

    cannot_receive_events!

    description <<-MD
      The Strava Activities agent reads public activities from your
      Strava account and creates events for new ones.
    MD

    default_schedule "every_1h"

    def default_options
      { 'include_private_activities' => false }
    end

    def working?
      last_seen > 0
    end

    def known_activities
      memory['known_activities'] || Set.new
    end

    def last_seen
      memory['last_known_activity'] || 0
    end

    # def last_seen=(activity_id)
    #   memory['last_known_activity'] = activity_id
    #   Rails.logger.info "Updated last seen: #{activity_id}"
    # end

    def check
      activities = strava.list_athlete_activities

      activities.sort!{ |a,b| a["id"] <=> b["id"] }

      activities.each do |activity|
        id = activity["id"]
        known_activities.add id

        if last_seen < id
          activity_details = strava.retrieve_an_activity(id)
          event = create_event payload: { activity: activity_details }
          log "New Strava activity: https://www.strava.com/activities/#{id}", outbound_event: event
          # last_seen = id
          memory['last_known_activity'] = id
        end
      end
    end

  end
end
