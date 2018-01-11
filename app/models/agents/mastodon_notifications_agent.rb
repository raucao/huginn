module Agents
  class MastodonNotificationsAgent < Agent
    # include MastodonConcern

    cannot_receive_events!

    description <<-MD
      The Mastodon User Agent follows your user notifications, including favs, boosts, and comments.

      There's no user interface for authenticating with an instance yet. Please create a credential for your user's OAuth token named `mastodon_user_token`.
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
        'include_mentions' => 'true',
        'include_follows' => 'true',
        'expected_update_period_in_days' => '14'
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
      since_id = memory['since_id'] || 0

      notifications = mastodon_client.notifications.to_a.map(&:to_hash)

      notifications.reject!{|n| n["type"] == 'favourite'} unless bool_opt('include_favs')
      notifications.reject!{|n| n["type"] == 'reblog'}    unless bool_opt('include_boosts')
      notifications.reject!{|n| n["type"] == 'mention'}   unless bool_opt('include_mentions')
      notifications.reject!{|n| n["type"] == 'follow'}    unless bool_opt('include_follows')

      notifications.each do |n|
        id = n['id'].to_i
        next unless id > since_id

        create_event :payload => n

        if !memory['since_id'] || (id > memory['since_id'])
          memory['since_id'] = id
        end
      end
    end

    private

    def mastodon_client
      @client ||= Mastodon::REST::Client.new(
        base_url: options['base_url'],
        bearer_token: options['user_token'] || credential('mastodon_user_token')
      )
    end

    def bool_opt(name)
      return true  if options[name] =~ (/^(true|t|yes|y|1)$/i)
      return false if options[name].blank? || options[name] =~ (/^(false|f|no|n|0)$/i)
    end

  end
end
