# frozen_string_literal: true

module RecordingStudioUsers
  class UserRoot < ApplicationRecord
    self.table_name = "recording_studio_users_user_roots"

    belongs_to :user, class_name: "User"
    belongs_to :current_profile, class_name: "RecordingStudioUsers::Profile", optional: true

    has_many :profiles,
             class_name: "RecordingStudioUsers::Profile",
             foreign_key: :user_root_id,
             inverse_of: :user_root,
             dependent: :restrict_with_exception

    validates :user_id, presence: true, uniqueness: true
    validates :root_recording_id, :profile_recording_id, :avatar_recording_id, presence: true
  end
end
