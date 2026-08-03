# frozen_string_literal: true

class CreateRecordingStudioUsersProfiles < ActiveRecord::Migration[8.1]
  def change
    create_profiles_table
    add_profile_indexes
    add_profile_constraints
  end

  private

  def create_profiles_table # rubocop:disable Metrics/MethodLength
    create_table :recording_studio_users_profiles, id: :uuid do |t|
      t.references(
        :user_root,
        null: false,
        type: :uuid,
        foreign_key: { to_table: :recording_studio_users_user_roots },
        index: { name: "idx_recording_studio_users_profiles_on_root" }
      )
      t.string :display_name, null: false
      t.string :given_name
      t.string :family_name
      t.string :pronouns
      t.text :bio
      t.string :locale
      t.string :time_zone
      t.jsonb :metadata, null: false, default: {}
      t.datetime :created_at, null: false
    end
  end # rubocop:enable Metrics/MethodLength

  def add_profile_indexes
    add_index :recording_studio_users_profiles, :display_name,
              name: "idx_recording_studio_users_profiles_on_name"
  end

  def add_profile_constraints
    add_check_constraint :recording_studio_users_profiles,
                         "char_length(display_name) <= 200",
                         name: "recording_studio_users_profiles_display_name_length"
    add_check_constraint :recording_studio_users_profiles,
                         "jsonb_typeof(metadata) = 'object'",
                         name: "recording_studio_users_profiles_metadata_object"
  end
end
