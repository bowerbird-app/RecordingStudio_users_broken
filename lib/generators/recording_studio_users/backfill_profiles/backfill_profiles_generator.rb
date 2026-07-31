# frozen_string_literal: true

require "rails/generators"

module RecordingStudioUsers
  module Generators
    class BackfillProfilesGenerator < Rails::Generators::Base
      desc "Backfill RecordingStudioUsers topology for existing users"

      def backfill
        klass = RecordingStudioUsers.user_class
        unless klass
          say "Could not resolve user class. Configure RecordingStudioUsers.user_class_name first.", :red
          return
        end

        klass.find_each do |user|
          next if RecordingStudioUsers.provisioned?(user)

          RecordingStudioUsers.provision(user, actor: user)
        end

        say "Backfill complete.", :green
      end
    end
  end
end
