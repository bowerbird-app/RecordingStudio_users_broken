# frozen_string_literal: true

module RecordingStudioUsers
  module Integrations
    module Accessible
      module_function

      def grant_first_access!(**)
        raise IntegrationUnavailableError,
              "RecordingStudioAccessible 0.4.1 has no public first-grant/bootstrap API; " \
              "configure a host-owned bootstrap policy instead"
      end
    end

    module Attachable
      module_function

      def install_profile_avatar!(**)
        raise IntegrationUnavailableError,
              "RecordingStudioAttachable 0.2.0 has no public singleton attachment or profile-avatar delivery contract"
      end
    end
  end
end
