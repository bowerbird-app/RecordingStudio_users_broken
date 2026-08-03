# frozen_string_literal: true

require "rails/generators"

module RecordingStudioUsers
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Install RecordingStudioUsers configuration without mounting routes or changing authentication"

      class_option :user_model,
                   type: :string,
                   default: nil,
                   desc: "Existing Active Record model that should include RecordingStudioUsers::User"

      def copy_initializer
        template "recording_studio_users.rb", "config/initializers/recording_studio_users.rb"
      end

      def include_user_concern
        return if options[:user_model].blank?

        model_name = options[:user_model].to_s
        unless Configuration::CONSTANT_NAME_PATTERN.match?(model_name)
          raise Thor::Error, "--user-model must be a constant name such as User or Accounts::User"
        end

        model_path = "app/models/#{model_name.underscore}.rb"
        absolute_path = File.join(destination_root, model_path)
        raise Thor::Error, "#{model_path} does not exist; no model was generated" unless File.file?(absolute_path)
        return if File.read(absolute_path).include?("RecordingStudioUsers::User")

        inject_into_class model_path, model_name, "  include RecordingStudioUsers::User\n"
      end

      def show_readme
        readme "INSTALL.md" if behavior == :invoke
      end
    end
  end
end
