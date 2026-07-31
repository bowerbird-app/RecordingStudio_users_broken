# frozen_string_literal: true

module RecordingStudioUsers
  class Profile < ApplicationRecord
    self.table_name = "recording_studio_users_profiles"

    belongs_to :user_root,
               class_name: "RecordingStudioUsers::UserRoot",
               inverse_of: :profiles

    scope :latest_first, -> { order(created_at: :desc) }

    def recordable_name
      display_name.to_s.strip.presence || "User profile"
    end
  end
end
