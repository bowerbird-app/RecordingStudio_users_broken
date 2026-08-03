# frozen_string_literal: true

require "recording_studio"
require "recording_studio_users/version"
require "recording_studio_users/errors"
require "recording_studio_users/configuration"
require "recording_studio_users/policy"
require "recording_studio_users/lookups"
require "recording_studio_users/loaders/user_loader"
require "recording_studio_users/presentation"
require "recording_studio_users/search/profiles"
require "recording_studio_users/services/profile_attributes"
require "recording_studio_users/services/provision_user"
require "recording_studio_users/services/revise_profile"
require "recording_studio_users/integrations/admin"
require "recording_studio_users/integrations/unsupported"
require "recording_studio_users/engine"

module RecordingStudioUsers
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
      configuration.validate!
      configuration
    end

    def reset_configuration!
      @configuration = Configuration.new
    end

    def register_recordables!
      RECORDABLE_TYPES.each { |type| RecordingStudio.register_recordable_type(type) }
      missing = RECORDABLE_TYPES.reject { |type| RecordingStudio.recordable_declaration_defined?(type) }
      return true if missing.empty?

      raise ConfigurationError, "Recording Studio declarations did not load for: #{missing.join(', ')}"
    end

    def user_root_for(user)
      Lookups.user_root_for(user)
    end

    def root_recording_for(user)
      Lookups.root_recording_for(user)
    end

    def profile_recording_for(user)
      Lookups.profile_recording_for(user)
    end

    def profile_for(user)
      Lookups.profile_for(user)
    end

    def load_user(id:)
      Loaders::UserLoader.call(id: id)
    end

    def display_name_for(user)
      Presentation.display_name_for(user)
    end

    def initials_for(user)
      Presentation.initials_for(user)
    end

    def policy_for(actor:, user: nil, record: nil)
      policy = configuration.policy_resolver.call(actor: actor, user: user, record: record)
      return policy if policy.respond_to?(:allowed?)

      raise ContractError, "policy_resolver must return an object responding to allowed?"
    end

    def authorize!(action, actor:, user: nil, record: nil)
      return true if policy_for(actor: actor, user: user, record: record).allowed?(action)

      raise UnauthorizedError, "#{action} is not permitted"
    end
  end

  RECORDABLE_TYPES = %w[
    RecordingStudioUsers::UserRoot
    RecordingStudioUsers::Profile
  ].freeze
end
