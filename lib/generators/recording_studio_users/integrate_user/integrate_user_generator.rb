# frozen_string_literal: true

require "rails/generators"

module RecordingStudioUsers
  module Generators
    class IntegrateUserGenerator < Rails::Generators::Base
      desc "Integrate RecordingStudioUsers concern into the host User model"

      def include_user_concern
        user_model_path = Rails.root.join("app/models/user.rb")

        unless File.exist?(user_model_path)
          say "No app/models/user.rb found. Create a User model and include RecordingStudioUsers::User manually.", :yellow
          return
        end

        return if File.read(user_model_path).include?("include RecordingStudioUsers::User")

        inject_into_class user_model_path, "User", "  include RecordingStudioUsers::User\n"
      end
    end
  end
end
