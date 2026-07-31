# frozen_string_literal: true

class CreateRecordingStudioUsersUserRoots < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_users_user_roots, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, index: { unique: true }
      t.uuid :root_recording_id, null: false
      t.uuid :profile_recording_id, null: false
      t.uuid :avatar_recording_id, null: false
      t.uuid :current_profile_id
      t.string :avatar_signed_blob_id
      t.string :avatar_content_type
      t.bigint :avatar_byte_size
      t.datetime :avatar_updated_at
      t.string :avatar_actor_type
      t.uuid :avatar_actor_id
      t.string :avatar_impersonator_type
      t.uuid :avatar_impersonator_id

      t.timestamps
    end

    add_index :recording_studio_users_user_roots, :root_recording_id, unique: true
    add_index :recording_studio_users_user_roots, :profile_recording_id, unique: true
    add_index :recording_studio_users_user_roots, :avatar_recording_id, unique: true
    add_index :recording_studio_users_user_roots, :current_profile_id
  end
end
