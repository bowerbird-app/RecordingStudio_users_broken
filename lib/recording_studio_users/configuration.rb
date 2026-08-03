# frozen_string_literal: true

module RecordingStudioUsers
  class Configuration
    MAX_PROFILE_SEARCH_LIMIT = 100
    CONSTANT_NAME_PATTERN = /\A[A-Z]\w*(?:::[A-Z]\w*)*\z/
    KEY_PATTERN = /\A[a-z][a-z0-9_]*\z/

    attr_reader :user_class_name, :profile_search_limit, :policy_resolver, :user_loader, :profile_searcher,
                :user_name_resolver, :admin_section_key, :register_admin_resource

    def initialize
      self.user_class_name = "User"
      self.profile_search_limit = 25
      self.policy_resolver = lambda do |actor:, user:, record:|
        RecordingStudioUsers::Policy.new(actor: actor, user: user, record: record)
      end
      self.user_loader = nil
      self.profile_searcher = nil
      self.user_name_resolver = ->(user) { RecordingStudioUsers::Presentation.fallback_name_for(user) }
      self.admin_section_key = "users"
      self.register_admin_resource = false
    end

    def user_class_name=(value)
      normalized = value.to_s.strip
      unless CONSTANT_NAME_PATTERN.match?(normalized)
        raise ConfigurationError, "user_class_name must be a constant name"
      end

      @user_class_name = normalized
    end

    def user_class
      user_class_name.safe_constantize ||
        raise(ConfigurationError, "configured user class #{user_class_name.inspect} is not loaded")
    end

    def profile_search_limit=(value)
      normalized = Integer(value)
      unless normalized.between?(1, MAX_PROFILE_SEARCH_LIMIT)
        raise ConfigurationError, "profile_search_limit must be between 1 and #{MAX_PROFILE_SEARCH_LIMIT}"
      end

      @profile_search_limit = normalized
    rescue ArgumentError, TypeError
      raise ConfigurationError, "profile_search_limit must be an integer"
    end

    def policy_resolver=(value)
      @policy_resolver = callable!(value, :policy_resolver)
    end

    def user_loader=(value)
      @user_loader = optional_callable!(value, :user_loader)
    end

    def profile_searcher=(value)
      @profile_searcher = optional_callable!(value, :profile_searcher)
    end

    def user_name_resolver=(value)
      @user_name_resolver = callable!(value, :user_name_resolver)
    end

    def admin_section_key=(value)
      normalized = value.to_s.strip
      raise ConfigurationError, "admin_section_key must be a lowercase key" unless KEY_PATTERN.match?(normalized)

      @admin_section_key = normalized
    end

    def register_admin_resource=(value)
      raise ConfigurationError, "register_admin_resource must be true or false" unless [true, false].include?(value)

      @register_admin_resource = value
    end

    def merge!(attributes)
      raise ConfigurationError, "configuration must be hash-like" unless attributes.respond_to?(:each_pair)

      attributes.each_pair do |key, value|
        setter = "#{key}="
        raise ConfigurationError, "unknown configuration key #{key.inspect}" unless respond_to?(setter)

        public_send(setter, value)
      end
      validate!
    end

    def validate!
      user_class_name
      profile_search_limit
      policy_resolver
      user_name_resolver
      self
    end

    def to_h
      {
        user_class_name: user_class_name,
        profile_search_limit: profile_search_limit,
        custom_user_loader: !user_loader.nil?,
        custom_profile_searcher: !profile_searcher.nil?,
        admin_section_key: admin_section_key,
        register_admin_resource: register_admin_resource
      }.freeze
    end

    private

    def callable!(value, name)
      return value if value.respond_to?(:call)

      raise ConfigurationError, "#{name} must respond to call"
    end

    def optional_callable!(value, name)
      return if value.nil?

      callable!(value, name)
    end
  end
end
