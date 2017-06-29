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

    def check
      query_options = { per_page: 200 }
      query_options[:after] = search_after if search_after

      activities = strava.list_athlete_activities(query_options)

      activities.sort!{ |a,b| a["id"] <=> b["id"] }

      unless include_private_activities?
        activities.reject!{ |a| a["private"] }
      end

      activities.each do |activity|
        id = activity["id"].to_s

        unless known_activities.include?(id)
          # Retrieve all details, incl. high-res polyline, segments, etc.
          activity_details = strava.retrieve_an_activity(id)
          # Create outgoing event to be consumed by other agents
          event = create_event payload: { activity: activity_details }
          # Update memory
          add_activity_to_memory(activity)
          # Log new activity linked to outbound event
          log "New Strava activity: https://www.strava.com/activities/#{id}", outbound_event: event
        end
      end
    end

    private

    def include_private_activities?
      # It's not possible to set proper boolean values in the config UI tree view
      options['include_private_activities'] &&
      options['include_private_activities'] != "false"
    end

    def known_activities
      if memory['known_activities']
        memory['known_activities'].split(",")
      else
        Array.new
      end
    end

    def last_seen
      memory['last_known_activity'] || 0
    end

    def last_seen=(activity_id)
      self.memory['last_known_activity'] = activity_id
    end

    def last_seen_date
      memory['last_known_activity_date']
    end

    def last_seen_date=(date)
      self.memory['last_known_activity_date'] = date
    end

    def search_after
      if last_seen_date
        # People oftentimes don't sync activities right away so we're looking for
        # everything uploaded within the last week
        (Time.at(last_seen_date) - 1.week).to_i
      else
        # The first sync will retrieve all past activities
        nil
      end
    end

    def add_activity_to_memory(activity)
      id = activity["id"]
      self.memory['known_activities'] = known_activities.to_set.add(id).to_a.join(",")
      self.last_seen = id
      self.last_seen_date = DateTime.parse(activity["start_date"]).to_time.to_i
    end

  end
end
