# frozen_string_literal: true

module RecordingStudioUsers
  class UserRoot < ApplicationRecord
    include RecordingStudio::Recordable

    self.table_name = "recording_studio_users_user_roots"

    belongs_to :user, polymorphic: true, inverse_of: :recording_studio_users_root
    has_many :profile_snapshots,
             class_name: "RecordingStudioUsers::Profile",
             inverse_of: :user_root,
             dependent: :restrict_with_error

    recording_studio_recordable label: "User", plural_label: "Users", root: true

    validates :user_type, :user_id, presence: true

    def name
      RecordingStudioUsers.display_name_for(user)
    end
  end
end
