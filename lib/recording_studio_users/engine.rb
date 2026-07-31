# frozen_string_literal: true

module RecordingStudioUsers
  class Engine < ::Rails::Engine
    isolate_namespace RecordingStudioUsers

    initializer "recording_studio_users.before_initialize", before: "recording_studio_users.load_config" do |_app|
      RecordingStudioUsers::Hooks.run(:before_initialize, self)
    end

    initializer "recording_studio_users.load_config" do |app|
      if app.respond_to?(:config_for)
        begin
          yaml = app.config_for(:recording_studio_users)
          RecordingStudioUsers.configuration.merge!(yaml) if yaml.respond_to?(:each)
        rescue StandardError
          nil
        end
      end

      if app.config.respond_to?(:x) && app.config.x.respond_to?(:recording_studio_users)
        xcfg = app.config.x.recording_studio_users
        begin
          if xcfg.respond_to?(:to_h)
            RecordingStudioUsers.configuration.merge!(xcfg.to_h)
          elsif xcfg.respond_to?(:each_pair)
            hash = {}
            xcfg.each_pair { |k, v| hash[k] = v }
            RecordingStudioUsers.configuration.merge!(hash)
          end
        rescue StandardError
          nil
        end
      end

      RecordingStudioUsers::Hooks.run(:on_configuration, RecordingStudioUsers.configuration)
    end

    initializer "recording_studio_users.after_initialize", after: "recording_studio_users.load_config" do |_app|
      RecordingStudioUsers::Hooks.run(:after_initialize, self)
    end

    initializer "recording_studio_users.apply_model_extensions" do
      config.to_prepare do
        next unless defined?(ActiveRecord::Base)

        ActiveRecord::Base.descendants.each do |model|
          next if model.abstract_class?

          RecordingStudioUsers::Engine.apply_model_extensions(model)
        end
      end
    end

    initializer "recording_studio_users.apply_controller_extensions" do
      config.to_prepare do
        next unless defined?(ActionController::Base)

        ActionController::Base.descendants.each do |controller|
          RecordingStudioUsers::Engine.apply_controller_extensions(controller)
        end
      end
    end

    initializer "recording_studio_users.helpers" do
      ActiveSupport.on_load(:action_controller_base) do
        helper RecordingStudioUsersHelper if defined?(RecordingStudioUsersHelper)
      end
    end

    class << self
      def apply_model_extensions(target)
        apply_extensions(target, RecordingStudioUsers.configuration.hooks.model_extensions_for(extension_keys_for(target)))
      end

      def apply_controller_extensions(target)
        apply_extensions(target, RecordingStudioUsers.configuration.hooks.controller_extensions_for(extension_keys_for(target)))
      end

      private

      def apply_extensions(target, extensions)
        return unless target

        applied = target.instance_variable_get(:@recording_studio_users_applied_extensions) || {}.compare_by_identity

        extensions.flatten.compact.each do |extension|
          next if applied[extension]

          target.class_eval(&extension)
          applied[extension] = true
        end

        target.instance_variable_set(:@recording_studio_users_applied_extensions, applied)
      end

      def extension_keys_for(target)
        names = [target.name, target.name&.demodulize].compact.uniq
        names.map(&:to_sym)
      end
    end
  end
end
