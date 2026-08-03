# frozen_string_literal: true

module RecordingStudioUsers
  module Loaders
    class UserLoader
      MAX_IDENTIFIER_LENGTH = 255

      class << self
        def call(id:)
          normalized_id = normalize_id(id)
          return if normalized_id.nil?

          user = custom_loader ? custom_loader.call(id: normalized_id) : user_class.find_by(id: normalized_id)
          validate_result!(user)
        end

        def call!(id:)
          call(id: id) || raise(ActiveRecord::RecordNotFound, "user was not found")
        end

        private

        def normalize_id(id)
          value = id.to_s.strip
          return if value.blank?
          raise ContractError, "user identifier is too long" if value.length > MAX_IDENTIFIER_LENGTH
          raise ContractError, "user identifier contains control characters" if value.match?(/[\u0000-\u001f\u007f]/)

          value
        end

        def custom_loader
          RecordingStudioUsers.configuration.user_loader
        end

        def user_class
          RecordingStudioUsers.configuration.user_class
        end

        def validate_result!(user)
          return if user.nil?
          return user if user.is_a?(user_class)

          raise ContractError, "user_loader must return a #{user_class.name} or nil"
        end
      end
    end
  end
end
