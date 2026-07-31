# frozen_string_literal: true

require "securerandom"

require "recording_studio_users/version"
require "recording_studio_users/engine"
require "recording_studio_users/configuration"
require "recording_studio_users/hooks"
require "recording_studio_users/services/base_service"
require "recording_studio_users/services/example_service"
require "recording_studio_users/user"
require "recording_studio_users/avatar"

module RecordingStudioUsers
  class Error < StandardError; end
  class ProvisioningError < Error; end
  class AuthorizationError < Error; end

  AVATAR_SIZES = %i[small medium large].freeze
  PROFILE_ATTRIBUTE_KEYS = %i[display_name biography locale time_zone].freeze
  FORBIDDEN_PROFILE_ATTRIBUTE_KEYS = %i[
    email encrypted_password password password_confirmation
    reset_password_token reset_password_sent_at
    current_sign_in_at current_sign_in_ip
    last_sign_in_at last_sign_in_ip
    failed_attempts unlock_token locked_at
  ].freeze

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end

    def user_class
      configuration.user_class
    end

    def provision(user, actor: nil)
      validate_persisted_user!(user)

      resolved_actor = configuration.resolve_provisioning_actor(user: user, actor: actor)
      validate_persisted_actor!(resolved_actor)

      with_retry_on_uniqueness do
        ActiveRecord::Base.transaction do
          root = UserRoot.lock.where(user_id: user.id).first_or_initialize

          if root.new_record?
            root.root_recording_id = SecureRandom.uuid
            root.profile_recording_id = SecureRandom.uuid
            root.avatar_recording_id = SecureRandom.uuid
            root.save!
          end

          profile = root.current_profile
          profile ||= root.profiles.create!(
            display_name: default_display_name_for(user),
            biography: nil,
            locale: configuration.default_locale,
            time_zone: configuration.default_time_zone,
            actor_type: resolved_actor.class.name,
            actor_id: resolved_actor.id
          )

          root.update!(current_profile: profile) unless root.current_profile_id == profile.id

          root
        end
      end
    end

    def provisioned?(user)
      return false unless user&.persisted?

      UserRoot.exists?(user_id: user.id)
    end

    def user_root_for(user)
      return unless user&.persisted?

      UserRoot.find_by(user_id: user.id)
    end

    def profile_recording_for(user)
      user_root_for(user)&.profile_recording_id
    end

    def profile_for(user)
      user_root_for(user)&.current_profile
    end

    def avatar_recording_for(user)
      user_root_for(user)&.avatar_recording_id
    end

    def validate_user_profile!(user)
      root = user_root_for(user)
      raise ProvisioningError, "User has not been provisioned" unless root
      raise ProvisioningError, "User is missing an active profile" unless root.current_profile

      true
    end

    def revise_profile(user:, actor:, attributes:, impersonator: nil)
      validate_persisted_user!(user)
      validate_persisted_actor!(actor)

      root = user_root_for(user)
      raise ProvisioningError, "User has not been provisioned" unless root
      raise AuthorizationError, "Profile is not editable" unless profile_editable?(viewer: actor, user: user)

      sanitized = sanitize_profile_attributes(attributes)
      profile = root.current_profile
      profile = root.profiles.create! if profile.nil?

      new_profile = root.profiles.create!(
        display_name: sanitized.fetch(:display_name, profile.display_name),
        biography: sanitized.fetch(:biography, profile.biography),
        locale: sanitized.fetch(:locale, profile.locale),
        time_zone: sanitized.fetch(:time_zone, profile.time_zone),
        actor_type: actor.class.name,
        actor_id: actor.id,
        impersonator_type: impersonator&.class&.name,
        impersonator_id: impersonator&.id
      )

      root.update!(current_profile: new_profile)
      new_profile
    end

    def upload_avatar(user:, signed_blob_id:, actor:, impersonator: nil)
      upsert_avatar(user: user, signed_blob_id: signed_blob_id, actor: actor, impersonator: impersonator)
    end

    def replace_avatar(user:, signed_blob_id:, actor:, impersonator: nil)
      upsert_avatar(user: user, signed_blob_id: signed_blob_id, actor: actor, impersonator: impersonator)
    end

    def remove_avatar(user:, actor:, impersonator: nil)
      validate_persisted_user!(user)
      validate_persisted_actor!(actor)

      root = user_root_for(user)
      raise ProvisioningError, "User has not been provisioned" unless root
      raise AuthorizationError, "Profile is not editable" unless profile_editable?(viewer: actor, user: user)

      root.update!(
        avatar_signed_blob_id: nil,
        avatar_content_type: nil,
        avatar_byte_size: nil,
        avatar_updated_at: Time.current,
        avatar_actor_type: actor.class.name,
        avatar_actor_id: actor.id,
        avatar_impersonator_type: impersonator&.class&.name,
        avatar_impersonator_id: impersonator&.id
      )

      true
    end

    def display_name(user, context: nil)
      current_profile = profile_for(user)
      name = current_profile&.display_name.to_s.strip
      return name if name.present? && identity_visible?(viewer: actor_from_context(context), user: user, context: context)

      resolver_name = resolve_user_label(user: user, context: context)
      return resolver_name if resolver_name.present?

      viewer = actor_from_context(context)
      if email_visible?(viewer: viewer, user: user, context: context)
        email = user.respond_to?(:email) ? user.email.to_s : ""
        local = email.split("@").first.to_s.strip
        return local.presence || "User"
      end

      "User"
    end

    def initials(user, context: nil)
      name = display_name(user, context: context).to_s
      chunks = name.scan(/\p{L}+/)
      return "U" if chunks.empty?

      return chunks.first[0].upcase if chunks.one?

      "#{chunks.first[0]}#{chunks.last[0]}".upcase
    end

    def avatar_for(user, size: :medium, context: nil)
      normalized_size = AVATAR_SIZES.include?(size.to_sym) ? size.to_sym : :medium
      width, height = configuration.avatar_variants.fetch(normalized_size)
      root = user_root_for(user)

      image_path = nil
      if root&.avatar_signed_blob_id.present? && configuration.authorized_avatar_path_resolver.respond_to?(:call)
        image_path = configuration.authorized_avatar_path_resolver.call(user: user, root: root, size: normalized_size, context: context)
      elsif configuration.external_avatar_resolver.respond_to?(:call)
        image_path = configuration.external_avatar_resolver.call(user: user, size: normalized_size, context: context)
      end

      Avatar.new(
        image_path: image_path,
        initials: initials(user, context: context),
        alt_text: display_name(user, context: context),
        width: width,
        height: height
      )
    end

    def profile_path_for(user, actor: nil, context: nil)
      viewer = actor || actor_from_context(context)
      return nil unless profile_visible?(viewer: viewer, user: user, context: context)

      return "/profile" unless defined?(Rails)

      helpers = Rails.application.routes.url_helpers
      return helpers.recording_studio_users.profile_path if helpers.respond_to?(:recording_studio_users)

      "/profile"
    rescue StandardError
      "/profile"
    end

    def profile_complete?(user)
      profile = profile_for(user)
      return false unless profile

      profile.display_name.to_s.strip.present?
    end

    def preload_user_information(users, include: %i[profile avatar], context: nil)
      requested = Array(include).map(&:to_sym)
      list = users.respond_to?(:to_a) ? users.to_a : Array(users)
      user_ids = list.map(&:id).compact

      roots = UserRoot.where(user_id: user_ids)
      roots = roots.includes(:current_profile) if requested.include?(:profile)
      roots_by_user_id = roots.index_by(&:user_id)

      UserInformationPreload.new(list, roots_by_user_id, requested, context)
    end

    def search_users(query:, actor:, context: nil, root: nil, exclude_ids: [], limit: nil)
      validate_persisted_actor!(actor)

      relation = user_class&.all
      return [] unless relation

      relation = configuration.search_scope_resolver.call(relation: relation, actor: actor, context: context) if configuration.search_scope_resolver.respond_to?(:call)
      relation = relation.where.not(id: exclude_ids) if exclude_ids.present?
      relation = relation.where(id: root.user_id) if root.respond_to?(:user_id)

      q = query.to_s.strip
      if q.present?
        escaped = ActiveRecord::Base.sanitize_sql_like(q)
        relation = relation.where("LOWER(COALESCE(email, '')) LIKE ?", "%#{escaped.downcase}%")
      elsif !site_search_authorized?(actor: actor, context: context)
        relation = relation.none
      end

      relation.limit([limit.to_i.positive? ? limit.to_i : configuration.picker_limit, configuration.picker_limit].min)
    end

    def identity_visible?(viewer:, user:, context: nil)
      evaluate_policy(configuration.identity_visible_policy, viewer: viewer, user: user, context: context)
    end

    def email_visible?(viewer:, user:, context: nil)
      evaluate_policy(configuration.email_visible_policy, viewer: viewer, user: user, context: context)
    end

    def profile_visible?(viewer:, user:, context: nil)
      evaluate_policy(configuration.profile_visible_policy, viewer: viewer, user: user, context: context)
    end

    def profile_editable?(viewer:, user:, context: nil)
      evaluate_policy(configuration.profile_editable_policy, viewer: viewer, user: user, context: context)
    end

    private

    def with_retry_on_uniqueness
      retries = 0
      begin
        yield
      rescue ActiveRecord::RecordNotUnique
        retries += 1
        retry if retries < 3
        raise ProvisioningError, "Could not provision user safely"
      end
    end

    def validate_persisted_user!(user)
      raise ProvisioningError, "User must be persisted" unless user&.persisted?
    end

    def validate_persisted_actor!(actor)
      raise ProvisioningError, "Actor must be persisted" unless actor&.respond_to?(:persisted?) && actor.persisted?
    end

    def sanitize_profile_attributes(attributes)
      attrs = attributes.to_h.symbolize_keys
      forbidden = attrs.keys & FORBIDDEN_PROFILE_ATTRIBUTE_KEYS
      raise ArgumentError, "Forbidden profile attributes: #{forbidden.join(', ')}" if forbidden.any?

      allowed_keys = configuration.profile_fields.map(&:to_sym)
      attrs.slice(*allowed_keys)
    end

    def resolve_user_label(user:, context: nil)
      return unless configuration.user_label_resolver.respond_to?(:call)

      configuration.user_label_resolver.call(user: user, context: context).to_s.strip.presence
    rescue StandardError
      nil
    end

    def actor_from_context(context)
      return context[:actor] if context.is_a?(Hash)
      return context.current_actor if context.respond_to?(:current_actor)

      nil
    end

    def site_search_authorized?(actor:, context: nil)
      return false unless configuration.site_search_authorizer.respond_to?(:call)

      configuration.site_search_authorizer.call(actor: actor, context: context)
    rescue StandardError
      false
    end

    def evaluate_policy(policy, viewer:, user:, context: nil)
      return false unless policy.respond_to?(:call)

      !!policy.call(viewer: viewer, user: user, context: context)
    rescue StandardError
      false
    end

    def upsert_avatar(user:, signed_blob_id:, actor:, impersonator: nil)
      validate_persisted_user!(user)
      validate_persisted_actor!(actor)

      root = user_root_for(user)
      raise ProvisioningError, "User has not been provisioned" unless root
      raise AuthorizationError, "Profile is not editable" unless profile_editable?(viewer: actor, user: user)
      raise ArgumentError, "signed_blob_id is required" if signed_blob_id.to_s.strip.empty?

      blob = validate_avatar_blob!(signed_blob_id)

      root.update!(
        avatar_signed_blob_id: signed_blob_id,
        avatar_content_type: blob&.content_type,
        avatar_byte_size: blob&.byte_size,
        avatar_updated_at: Time.current,
        avatar_actor_type: actor.class.name,
        avatar_actor_id: actor.id,
        avatar_impersonator_type: impersonator&.class&.name,
        avatar_impersonator_id: impersonator&.id
      )

      root
    end

    def validate_avatar_blob!(signed_blob_id)
      return unless defined?(ActiveStorage::Blob)

      blob = ActiveStorage::Blob.find_signed!(signed_blob_id)
      if blob.content_type.present? && configuration.avatar_allowed_content_types.present?
        allowed = configuration.avatar_allowed_content_types.any? do |value|
          value.end_with?("/*") ? blob.content_type.start_with?(value.delete_suffix("*")) : blob.content_type == value
        end
        raise ArgumentError, "Avatar content type is not allowed" unless allowed
      end

      if configuration.avatar_max_size.present? && blob.byte_size.to_i > configuration.avatar_max_size.to_i
        raise ArgumentError, "Avatar exceeds configured size limit"
      end

      blob
    rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
      raise ArgumentError, "Invalid avatar upload token"
    end

    def default_display_name_for(user)
      return user.email.to_s.split("@").first if user.respond_to?(:email) && user.email.present?

      "User"
    end
  end

  class UserInformationPreload
    attr_reader :users, :requested_includes, :context

    def initialize(users, roots_by_user_id, requested_includes, context)
      @users = users
      @roots_by_user_id = roots_by_user_id
      @requested_includes = requested_includes
      @context = context
    end

    def root_for(user)
      @roots_by_user_id[user.id]
    end

    def profile_for(user)
      root_for(user)&.current_profile
    end

    def avatar_for(user, size: :medium)
      RecordingStudioUsers.avatar_for(user, size: size, context: context)
    end
  end
end
