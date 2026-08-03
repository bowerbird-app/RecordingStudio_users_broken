# frozen_string_literal: true

module RecordingStudioUsers
  module Presentation
    module_function

    def display_name_for(user)
      profile_name = RecordingStudioUsers.profile_for(user)&.display_name.to_s.squish.presence
      profile_name || resolved_user_name(user) || "User"
    end

    def initials_for(user)
      words = display_name_for(user).scan(/[[:alnum:]]+/)
      initials = words.first(2).filter_map { |word| word[0] }.join.upcase
      initials.presence || "U"
    end

    def fallback_name_for(user)
      return if user.nil?

      %i[display_name name email].each do |method_name|
        next unless user.respond_to?(method_name)

        value = user.public_send(method_name).to_s.squish.presence
        return value if value
      end

      nil
    end

    def resolved_user_name(user)
      value = RecordingStudioUsers.configuration.user_name_resolver.call(user)
      value.to_s.squish.presence
    rescue StandardError => e
      raise ContractError, "user_name_resolver failed: #{e.message}"
    end
    private_class_method :resolved_user_name
  end
end
