# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module RecordingStudioUsers
  module Generators
    class MigrationsGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("../../../..", __dir__)

      desc "Copy RecordingStudioUsers migrations to the host application"

      class_option :skip_existing,
                   type: :boolean,
                   default: true,
                   desc: "Skip migrations whose logical names already exist"

      def copy_migrations
        migration_files.each do |source_path|
          logical_name = File.basename(source_path).sub(/^\d+_/, "")
          if options[:skip_existing] && migration_exists?(logical_name)
            say "  skip  #{logical_name} (already exists)", :yellow
            next
          end

          destination = File.join("db/migrate", "#{next_migration_number}_#{logical_name}")
          copy_file source_path, destination
          say "  create  #{destination}", :green
        end

        say "Run 'bin/rails db:migrate' to apply the migrations.", :green
      end

      private

      def migration_files
        Dir.glob(File.join(self.class.source_root, "db/migrate/*.rb"))
      end

      def migration_exists?(logical_name)
        Dir.glob(File.join(destination_root, "db/migrate/*.rb")).any? do |path|
          File.basename(path).sub(/^\d+_/, "") == logical_name
        end
      end

      def next_migration_number
        @next_migration_number ||= [current_timestamp, latest_destination_version + 1].max
        current_number = @next_migration_number
        @next_migration_number += 1
        current_number.to_s
      end

      def current_timestamp
        Time.now.utc.strftime("%Y%m%d%H%M%S").to_i
      end

      def latest_destination_version
        Dir.glob(File.join(destination_root, "db/migrate/*.rb")).filter_map do |path|
          File.basename(path)[/\A\d+/]&.to_i
        end.max.to_i
      end
    end
  end
end
