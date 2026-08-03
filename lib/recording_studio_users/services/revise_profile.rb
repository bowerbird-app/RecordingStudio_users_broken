# frozen_string_literal: true

module RecordingStudioUsers
  module Services
    class ReviseProfile
      class << self
        def call(...)
          new(...).call
        end
      end

      def initialize(user:, actor:, profile_attributes:, expected_profile_id: nil, event_metadata: {})
        @user = user
        @actor = actor
        @profile_attributes = ProfileAttributes.normalize(profile_attributes)
        @expected_profile_id = expected_profile_id&.to_s
        @event_metadata = normalize_event_metadata(event_metadata)
      end

      def call
        RecordingStudioUsers.authorize!(:update, actor: actor, user: user)
        root_recording = locked_root_recording
        root_recording.with_lock { revise_locked_profile(root_recording) }
      end

      private

      attr_reader :user, :actor, :profile_attributes, :expected_profile_id, :event_metadata

      def locked_root_recording
        root_recording = RecordingStudioUsers.root_recording_for(user)
        raise UserNotProvisionedError, "user does not have a Recording Studio user root" unless root_recording

        RecordingStudio::Recording.unscoped.lock.find(root_recording.id)
      end

      def revise_locked_profile(root_recording)
        profile_recording = Lookups.profile_recording_for_root_recording(root_recording)
        raise UserNotProvisionedError, "user does not have a profile recording" unless profile_recording

        current_profile = profile_recording.recordable
        verify_expected_profile!(current_profile)
        return current_profile if unchanged?(current_profile)

        root_recording.revise(profile_recording, actor: actor, metadata: event_metadata) do |profile|
          profile.assign_attributes(profile_attributes)
        end.recordable
      end

      def normalize_event_metadata(value)
        raise InvalidProfileAttributesError, "event_metadata must be a hash" unless value.respond_to?(:to_h)

        value.to_h.deep_stringify_keys
      end

      def verify_expected_profile!(profile)
        return if expected_profile_id.nil? || expected_profile_id == profile.id.to_s

        raise StaleProfileError, "profile changed before this revision was applied"
      end

      def unchanged?(profile)
        profile_attributes.all? do |attribute, value|
          profile.public_send(attribute) == value
        end
      end
    end
  end
end
