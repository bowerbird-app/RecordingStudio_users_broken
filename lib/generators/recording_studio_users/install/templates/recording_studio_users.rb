# frozen_string_literal: true

RecordingStudioUsers.configure do |config|
  # The host model that includes RecordingStudioUsers::User.
  config.user_class_name = "User"

  # Search is authorization-gated and capped at 100 results.
  config.profile_search_limit = 25

  # Optional and disabled by default. Requires RecordingStudioAdmin's public
  # Resource/register_resource API and an existing matching admin section.
  config.register_admin_resource = false
  config.admin_section_key = "users"

  # Replace policy_resolver to grant anything beyond self-service reads/writes.
  # config.policy_resolver = ->(actor:, user:, record:) { MyUsersPolicy.new(actor:, user:, record:) }
end
