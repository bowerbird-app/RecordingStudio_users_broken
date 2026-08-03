# frozen_string_literal: true

module RecordingStudioUsers
  module Integrations
    module Admin
      module_function

      def available?
        defined?(RecordingStudioAdmin::Resource) &&
          RecordingStudioAdmin.respond_to?(:register_resource)
      end

      def register!
        unless available?
          raise IntegrationUnavailableError,
                "RecordingStudioAdmin registration requires its public Resource and register_resource APIs"
        end

        resource = users_resource
        resource.section(RecordingStudioUsers.configuration.admin_section_key)
        RecordingStudioAdmin.register_resource(resource)
      end

      def users_resource
        return RecordingStudioUsers::Admin::UsersResource if defined?(RecordingStudioUsers::Admin::UsersResource)

        admin_namespace = if RecordingStudioUsers.const_defined?(:Admin, false)
                            RecordingStudioUsers.const_get(:Admin)
                          else
                            RecordingStudioUsers.const_set(:Admin, Module.new)
                          end
        resource = Class.new(RecordingStudioAdmin::Resource)
        resource.key("recording_studio_users")
        resource.title("Users")
        admin_namespace.const_set(:UsersResource, resource)
      end
      private_class_method :users_resource
    end
  end
end
