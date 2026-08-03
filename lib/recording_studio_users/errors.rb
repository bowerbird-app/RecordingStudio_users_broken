# frozen_string_literal: true

module RecordingStudioUsers
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class ContractError < Error; end
  class UnauthorizedError < Error; end
  class UserNotPersistedError < Error; end
  class UserNotProvisionedError < Error; end
  class InvalidProfileAttributesError < Error; end
  class StaleProfileError < Error; end
  class IntegrationUnavailableError < Error; end
end
