# frozen_string_literal: true

require "rails/generators"

module RecordingStudioUsers
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Installs RecordingStudioUsers into your host application"

      class_option :mount_path, type: :string, default: "/recording_studio_users", desc: "Mount path for the engine"

      def verify_dependencies
        missing = []
        %w[recording_studio recording_studio_accessible recording_studio_attachable recording_studio_admin devise flat_pack].each do |name|
          missing << name unless gem_available?(name)
        end

        return if missing.empty?

        say "Missing recommended gems: #{missing.join(', ')}", :yellow
      end

      def install_devise_when_missing
        return if File.exist?(Rails.root.join("config/initializers/devise.rb"))

        say "Devise initializer missing; run `bin/rails generate devise:install` if needed.", :yellow
      end

      def mount_engine
        route %(mount RecordingStudioUsers::Engine, at: "#{options[:mount_path]}")
      end

      def copy_initializer
        template "recording_studio_users_initializer.rb", "config/initializers/recording_studio_users.rb"
      end

      def copy_migrations
        generate "recording_studio_users:migrations"
      end

      def integrate_user_model
        generate "recording_studio_users:integrate_user"
      end

      def print_next_steps
        readme "INSTALL.md" if behavior == :invoke
      end

      private

      def gem_available?(name)
        Gem.loaded_specs.key?(name)
      end
    end
  end
end
