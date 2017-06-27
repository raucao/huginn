require 'strava/api/v3'

module StravaConcern
  extend ActiveSupport::Concern

  included do
    include Oauthable

    validate :validate_strava_options
    valid_oauth_providers :strava

    gem_dependency_check { Devise.omniauth_providers.include?(:strava) && ENV['STRAVA_OAUTH_KEY'].present? && ENV['STRAVA_OAUTH_SECRET'].present? }
  end

  def validate_strava_options
    unless strava_consumer_key.present? &&
      strava_consumer_secret.present? &&
      strava_oauth_token.present? &&
      errors.add(:base, "Strava consumer_key, consumer_secret, oauth_token, and are required to authenticate with the Strava API. You can provide these as options to this Agent, or as Credentials with the same names, but starting with 'strava_'.")
    end
  end

  def strava_consumer_key
    (config = Devise.omniauth_configs[:strava]) && config.strategy.consumer_key
  end

  def strava_consumer_secret
    (config = Devise.omniauth_configs[:strava]) && config.strategy.consumer_secret
  end

  def strava_oauth_token
    service && service.token
  end

  def strava
    @strava ||= Strava::Api::V3::Client.new(:access_token => strava_oauth_token)
  end

  module ClassMethods
    def strava_dependencies_missing
      if ENV['STRAVA_OAUTH_KEY'].blank? || ENV['STRAVA_OAUTH_SECRET'].blank?
        "## Set STRAVA_OAUTH_KEY and STRAVA_OAUTH_SECRET in your environment to use Twitter Agents."
      elsif !Devise.omniauth_providers.include?(:strava)
        "## Include the `omniauth-strava` gems in your Gemfile to use Strava Agents."
      end
    end
  end
end
