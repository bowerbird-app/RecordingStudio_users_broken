# frozen_string_literal: true

class CreateRecordingStudioUsersUserRoots < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_users_user_roots, id: :uuid do |t|
      t.references :user, polymorphic: true, null: false, type: :uuid, index: false
      t.datetime :created_at, null: false
    end

    add_index(
      :recording_studio_users_user_roots,
      %i[user_type user_id],
      unique: true,
      name: "idx_recording_studio_users_roots_on_user"
    )
  end
end
