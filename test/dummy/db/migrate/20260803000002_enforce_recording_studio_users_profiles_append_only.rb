# frozen_string_literal: true

class EnforceRecordingStudioUsersProfilesAppendOnly < ActiveRecord::Migration[8.1]
  FUNCTION_NAME = "recording_studio_users_reject_profile_mutation"
  TRIGGER_NAME = "recording_studio_users_profiles_append_only"

  def up
    execute <<~SQL
      CREATE FUNCTION #{FUNCTION_NAME}()
      RETURNS trigger
      LANGUAGE plpgsql
      AS $function$
      BEGIN
        RAISE EXCEPTION 'recording_studio_users_profiles is append-only'
          USING ERRCODE = 'integrity_constraint_violation';
      END;
      $function$;

      CREATE TRIGGER #{TRIGGER_NAME}
      BEFORE UPDATE OR DELETE ON recording_studio_users_profiles
      FOR EACH ROW EXECUTE FUNCTION #{FUNCTION_NAME}();
    SQL
  end

  def down
    execute "DROP TRIGGER IF EXISTS #{TRIGGER_NAME} ON recording_studio_users_profiles"
    execute "DROP FUNCTION IF EXISTS #{FUNCTION_NAME}()"
  end
end
