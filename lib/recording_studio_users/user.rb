# frozen_string_literal: true

module RecordingStudioUsers
  module User
    extend ActiveSupport::Concern

    included do
      has_one :recording_studio_users_user_root,
              class_name: "RecordingStudioUsers::UserRoot",
              foreign_key: :user_id,
              inverse_of: :user,
              dependent: nil

      has_many :recording_studio_users_profiles,
               through: :recording_studio_users_user_root,
               source: :profiles
    end

    def recording_studio_user_root
      recording_studio_users_user_root
    end

    def recording_studio_profile
      recording_studio_users_user_root&.current_profile
    end

    def recording_studio_provisioned?
      RecordingStudioUsers.provisioned?(self)
    end
  end
end
