module Agents
  class MastodonNotificationsAgent < Agent
    # include MastodonConcern

    cannot_receive_events!

    description <<-MD
      The Mastodon User Agent follows your user notifications, including favs,
      boosts, and comments.

      There's no user interface for authenticating with an instance yet. Please
      create a credential for your user's OAuth token named `mastodon_user_token`.
    MD

    default_schedule "every_1h"

    def working?
      event_created_within?(interpolated['expected_update_period_in_days']) && !recent_error_logs?
    end

    def default_options
      {
        'user_address' => 'raucao@kosmos.social',
        'base_url' => 'https://kosmos.social',
        'user_token' => '123abc',
        'include_favs' => 'true',
        'include_boosts' => 'true',
        'exclude_replies' => 'true',
        'expected_update_period_in_days' => '7'
      }
    end

    def validate_options
      errors.add(:base, "expected_update_period_in_days is required") unless options['expected_update_period_in_days'].present?
      errors.add(:base, "user address is required") if options['user_address'].blank?

      if options[:include_boosts].present? && !%w[true false].include?(options[:include_boosts])
        errors.add(:base, "include_boosts must be a boolean value string (true/false)")
      end
    end

    def include_boosts?
      interpolated[:include_boosts] != "false"
    end

    def exclude_replies?
      boolify(interpolated[:exclude_replies]) || false
    end

    def starting_at
      if interpolated[:starting_at].present?
        Time.parse(interpolated[:starting_at]) rescue created_at
      else
        created_at
      end
    end

    def check
      # since_id = memory['since_id'] || 0

      # opts = {:count => 200, :include_rts => include_retweets?, :exclude_replies => exclude_replies?, :include_entities => true, :contributor_details => true, tweet_mode: 'extended'}
      # opts.merge! :since_id => since_id unless since_id.nil?

      notifications = mastodon_client.notifications

      log notifications.size

      notifications.each do |n|
        # if n.created_at >= starting_at
          # memory['since_id'] = n.id if !memory['since_id'] || (n.id > memory['since_id'])

        create_event :payload => n.to_hash
        # end
      end
    end

    private

    def mastodon_client
      @client ||= Mastodon::REST::Client.new(
        base_url: options['base_url'],
        bearer_token: options['user_token'] || credential('mastodon_user_token')
      )
    end

  end
end
