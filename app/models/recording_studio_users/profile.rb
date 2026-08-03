# frozen_string_literal: true

require "json"

module RecordingStudioUsers
  class Profile < ApplicationRecord
    include RecordingStudio::Recordable

    EDITABLE_ATTRIBUTES = Services::ProfileAttributes::EDITABLE_ATTRIBUTES
    MAX_METADATA_BYTES = 16.kilobytes

    self.table_name = "recording_studio_users_profiles"

    belongs_to :user_root, inverse_of: :profile_snapshots

    recording_studio_recordable(
      label: "Profile",
      plural_label: "Profiles",
      root: false,
      allowed_parent_types: ["RecordingStudioUsers::UserRoot"]
    )

    validates :display_name, presence: true, length: { maximum: 200 }
    validates :given_name, :family_name, :pronouns, length: { maximum: 100 }, allow_nil: true
    validates :locale, length: { maximum: 32 }, allow_nil: true
    validates :time_zone, length: { maximum: 100 }, allow_nil: true
    validates :bio, length: { maximum: 5000 }, allow_nil: true
    validate :metadata_is_bounded_object

    def name
      display_name
    end

    private

    def metadata_is_bounded_object
      unless metadata.is_a?(Hash)
        errors.add(:metadata, "must be an object")
        return
      end

      errors.add(:metadata, "is too large") if JSON.generate(metadata).bytesize > MAX_METADATA_BYTES
    end
  end
end
