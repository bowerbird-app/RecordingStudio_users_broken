# frozen_string_literal: true

module RecordingStudioUsers
  module User
    extend ActiveSupport::Concern

    included do
      has_one :recording_studio_users_root,
              as: :user,
              class_name: "RecordingStudioUsers::UserRoot",
              inverse_of: :user,
              dependent: :restrict_with_error
    end

    def recording_studio_users_root_recording
      RecordingStudioUsers.root_recording_for(self)
    end

    def recording_studio_users_profile_recording
      RecordingStudioUsers.profile_recording_for(self)
    end

    def recording_studio_users_profile
      RecordingStudioUsers.profile_for(self)
    end

    def recording_studio_users_display_name
      RecordingStudioUsers.display_name_for(self)
    end

    def recording_studio_users_initials
      RecordingStudioUsers.initials_for(self)
    end
  end
end
