# frozen_string_literal: true

module RecordingStudioUsers
  module Services
    module ProfileAttributes
      EDITABLE_ATTRIBUTES = %i[
        display_name
        given_name
        family_name
        pronouns
        bio
        locale
        time_zone
        metadata
      ].freeze
      SQUISHED_ATTRIBUTES = %i[display_name given_name family_name pronouns locale time_zone].freeze

      module_function

      def normalize(attributes)
        raise InvalidProfileAttributesError, "profile attributes must be hash-like" unless attributes.respond_to?(:to_h)

        values = attributes.to_h.symbolize_keys
        unknown = values.keys - EDITABLE_ATTRIBUTES
        raise InvalidProfileAttributesError, "unknown profile attributes: #{unknown.sort.join(', ')}" if unknown.any?

        values.each_with_object({}) do |(key, value), normalized|
          normalized[key] = normalize_value(key, value)
        end
      end

      def normalize_value(key, value)
        return normalize_metadata(value) if key == :metadata
        return value unless SQUISHED_ATTRIBUTES.include?(key)

        value.to_s.squish.presence
      end
      private_class_method :normalize_value

      def normalize_metadata(value)
        return {} if value.nil?
        raise InvalidProfileAttributesError, "profile metadata must be a hash" unless value.respond_to?(:to_h)

        value.to_h.deep_stringify_keys
      end
      private_class_method :normalize_metadata
    end
  end
end
