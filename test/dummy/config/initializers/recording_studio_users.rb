# frozen_string_literal: true

RecordingStudioUsers.configure do |config|
  config.user_class_name = "User"
  config.profile_search_limit = 25
  config.register_admin_resource = false
end
