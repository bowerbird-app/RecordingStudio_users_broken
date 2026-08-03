# frozen_string_literal: true

module RecordingStudioUsers
  module Services
    class ProvisionUser
      Result = Data.define(:user_root, :root_recording, :profile_recording, :profile)

      class << self
        def call(...)
          new(...).call
        end
      end

      def initialize(user:, actor:, profile_attributes: {})
        @user = user
        @actor = actor
        @profile_attributes = ProfileAttributes.normalize(profile_attributes)
      end

      def call
        validate_user!
        RecordingStudioUsers.authorize!(:provision, actor: actor, user: user)

        UserRoot.transaction do
          user_root = UserRoot.create_or_find_by!(user: user)
          user_root.lock!
          root_recording = RecordingStudio.root_recording_for(user_root)
          profile_recording = Lookups.profile_recording_for_root_recording(root_recording)
          profile_recording ||= create_profile_recording(root_recording, user_root)

          Result.new(user_root, root_recording, profile_recording, profile_recording.recordable)
        end
      end

      private

      attr_reader :user, :actor, :profile_attributes

      def validate_user!
        unless user.respond_to?(:persisted?) && user.persisted?
          raise UserNotPersistedError, "user must be persisted before provisioning"
        end
        return if user.class.type_for_attribute(user.class.primary_key).type == :uuid

        raise ConfigurationError, "RecordingStudioUsers requires a UUID primary key on #{user.class.name}"
      end

      def create_profile_recording(root_recording, user_root)
        attributes = profile_attributes.dup
        resolved_name = RecordingStudioUsers.configuration.user_name_resolver.call(user).to_s.squish.presence
        attributes[:display_name] ||= resolved_name
        attributes[:display_name] ||= "User"

        root_recording.record(Profile, actor: actor, parent_recording: root_recording) do |profile|
          profile.user_root = user_root
          profile.assign_attributes(attributes)
        end
      end
    end
  end
end
