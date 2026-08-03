# frozen_string_literal: true

module RecordingStudioUsers
  class Engine < ::Rails::Engine
    isolate_namespace RecordingStudioUsers

    config.to_prepare do
      RecordingStudioUsers.register_recordables!
      RecordingStudioUsers::Integrations::Admin.register! if RecordingStudioUsers.configuration.register_admin_resource
    end
  end
end
