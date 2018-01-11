# require 'mastodon'
#
# module MastodonConcern
#   extend ActiveSupport::Concern
#
#   included do
#     include Oauthable
#
#     validate :validate_mastodon_options
#     valid_oauth_providers :mastodon
#
#     gem_dependency_check { Devise.omniauth_providers.include?(:mastodon) && ENV['mastodon_OAUTH_KEY'].present? && ENV['mastodon_OAUTH_SECRET'].present? }
#   end
#
#   def validate_mastodon_options
#     unless mastodon_consumer_key.present? &&
#       mastodon_consumer_secret.present? &&
#       mastodon_oauth_token.present? &&
#       errors.add(:base, "mastodon consumer_key, consumer_secret, oauth_token, and are required to authenticate with the mastodon API. You can provide these as options to this Agent, or as Credentials with the same names, but starting with 'mastodon_'.")
#     end
#   end
#
#   def mastodon_consumer_key
#     (config = Devise.omniauth_configs[:mastodon]) && config.strategy.consumer_key
#   end
#
#   def mastodon_consumer_secret
#     (config = Devise.omniauth_configs[:mastodon]) && config.strategy.consumer_secret
#   end
#
#   def mastodon_oauth_token
#     service && service.token
#   end
#
#   def mastodon
#     @mastodon ||= mastodon::Api::V3::Client.new(:access_token => mastodon_oauth_token)
#   end
#
#   module ClassMethods
#     def mastodon_dependencies_missing
#       if ENV['mastodon_OAUTH_KEY'].blank? || ENV['mastodon_OAUTH_SECRET'].blank?
#         "## Set mastodon_OAUTH_KEY and mastodon_OAUTH_SECRET in your environment to use Twitter Agents."
#       elsif !Devise.omniauth_providers.include?(:mastodon)
#         "## Include the `omniauth-mastodon` gems in your Gemfile to use mastodon Agents."
#       end
#     end
#   end
# end
