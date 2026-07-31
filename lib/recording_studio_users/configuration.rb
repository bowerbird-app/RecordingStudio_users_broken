# frozen_string_literal: true

require_relative "hooks"

module RecordingStudioUsers
  class Configuration
    DEFAULT_PROFILE_FIELDS = %i[display_name biography locale time_zone].freeze
    DEFAULT_AVATAR_VARIANTS = {
      small: [32, 32],
      medium: [64, 64],
      large: [128, 128]
    }.freeze

    attr_accessor :api_key,
                  :enable_feature_x,
                  :timeout,
                  :user_class_name,
                  :registration_enabled,
                  :profile_fields,
                  :default_locale,
                  :default_time_zone,
                  :picker_limit,
                  :avatar_allowed_content_types,
                  :avatar_max_size,
                  :avatar_variants,
                  :user_label_resolver,
                  :external_avatar_resolver,
                  :provisioning_actor_resolver,
                  :identity_visible_policy,
                  :email_visible_policy,
                  :profile_visible_policy,
                  :profile_editable_policy,
                  :search_scope_resolver,
                  :site_search_authorizer,
                  :authorized_avatar_path_resolver

    attr_reader :hooks

    def initialize
      @api_key = ENV.fetch("RECORDING_STUDIO_USERS_API_KEY", nil)
      @enable_feature_x = false
      @timeout = 5
      @hooks = Hooks.new

      @user_class_name = "User"
      @registration_enabled = true
      @profile_fields = DEFAULT_PROFILE_FIELDS.dup
      @default_locale = "en"
      @default_time_zone = "UTC"
      @picker_limit = 20
      @avatar_allowed_content_types = ["image/png", "image/jpeg", "image/webp", "image/gif"]
      @avatar_max_size = 10.megabytes
      @avatar_variants = DEFAULT_AVATAR_VARIANTS.dup

      @provisioning_actor_resolver = ->(user:, actor: nil) { actor || user }
      @identity_visible_policy = ->(viewer:, user:, context: nil) { viewer.present? && viewer == user }
      @email_visible_policy = ->(viewer:, user:, context: nil) { viewer.present? && viewer == user }
      @profile_visible_policy = ->(viewer:, user:, context: nil) { viewer.present? && viewer == user }
      @profile_editable_policy = ->(viewer:, user:, context: nil) { viewer.present? && viewer == user }
      @search_scope_resolver = ->(relation:, actor:, context: nil) { relation }
      @site_search_authorizer = ->(actor:, context: nil) { false }
    end

    def user_class
      user_class_name.constantize
    rescue NameError
      nil
    end

    def resolve_provisioning_actor(user:, actor: nil)
      return actor if actor.present?
      return unless provisioning_actor_resolver.respond_to?(:call)

      provisioning_actor_resolver.call(user: user, actor: actor)
    end

    def to_h
      {
        api_key: api_key,
        enable_feature_x: enable_feature_x,
        timeout: timeout,
        user_class_name: user_class_name,
        registration_enabled: registration_enabled,
        profile_fields: profile_fields,
        default_locale: default_locale,
        default_time_zone: default_time_zone,
        picker_limit: picker_limit,
        avatar_allowed_content_types: avatar_allowed_content_types,
        avatar_max_size: avatar_max_size,
        avatar_variants: avatar_variants,
        hooks_registered: hooks.instance_variable_get(:@registry).transform_values(&:size)
      }
    end

    def merge!(hash)
      return unless hash.respond_to?(:each)

      hash.each do |k, v|
        key = k.to_s
        setter = "#{key}="
        public_send(setter, v) if respond_to?(setter)
      end
    end
  end
end
