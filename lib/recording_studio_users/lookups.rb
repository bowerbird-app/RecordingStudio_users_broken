# frozen_string_literal: true

module RecordingStudioUsers
  module Lookups
    module_function

    def user_root_for(user)
      return unless persisted_record?(user)

      RecordingStudioUsers::UserRoot.find_by(user: user)
    end

    def root_recording_for(user)
      user_root = user_root_for(user)
      return unless user_root

      RecordingStudio::Recording.unscoped.find_by(recordable: user_root, parent_recording_id: nil)
    end

    def profile_recording_for(user)
      profile_recording_for_root_recording(root_recording_for(user))
    end

    def profile_recording_for_root_recording(root_recording)
      return unless root_recording

      root_recording.recordings_query(
        include_children: true,
        type: "RecordingStudioUsers::Profile",
        parent_id: root_recording.id,
        limit: 1
      ).first
    end

    def profile_for(user)
      profile_recording_for(user)&.recordable
    end

    def persisted_record?(record)
      record.respond_to?(:persisted?) && record.persisted?
    end
    private_class_method :persisted_record?
  end
end
