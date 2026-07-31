# frozen_string_literal: true

class CreateRecordingStudioUsersProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_users_profiles, id: :uuid do |t|
      t.references :user_root, null: false, type: :uuid, foreign_key: { to_table: :recording_studio_users_user_roots }
      t.string :display_name
      t.text :biography
      t.string :locale
      t.string :time_zone
      t.string :actor_type
      t.uuid :actor_id
      t.string :impersonator_type
      t.uuid :impersonator_id

      t.timestamps
    end

    add_index :recording_studio_users_profiles, %i[user_root_id created_at]
  end
end
