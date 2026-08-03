# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "tmpdir"
require "generators/recording_studio_users/install/install_generator"
require "generators/recording_studio_users/migrations/migrations_generator"

class InstallGeneratorTest < Minitest::Test
  def test_install_copies_only_initializer_by_default
    with_temp_app do |root|
      generator = install_generator(root)
      generator.stub(:say, nil) { generator.copy_initializer }

      assert File.exist?(File.join(root, "config/initializers/recording_studio_users.rb"))
      refute File.exist?(File.join(root, "config/routes.rb"))
      refute File.exist?(File.join(root, "app/models/user.rb"))
    end
  end

  def test_user_concern_is_only_injected_when_explicit
    with_temp_app do |root|
      path = File.join(root, "app/models/user.rb")
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, "class User < ApplicationRecord\nend\n")

      generator = install_generator(root, user_model: "User")
      generator.stub(:say, nil) { generator.include_user_concern }

      source = File.read(path)
      assert_includes source, "include RecordingStudioUsers::User"

      generator.stub(:say, nil) { generator.include_user_concern }
      assert_equal 1, File.read(path).scan("include RecordingStudioUsers::User").size
    end
  end

  def test_user_model_option_rejects_invalid_or_missing_models
    with_temp_app do |root|
      invalid = install_generator(root, user_model: "../../User")
      missing = install_generator(root, user_model: "Accounts::User")

      assert_raises(Thor::Error) { invalid.include_user_concern }
      assert_raises(Thor::Error) { missing.include_user_concern }
    end
  end

  def test_migration_generator_copies_both_migrations_without_overwriting
    with_temp_app do |root|
      FileUtils.mkdir_p(File.join(root, "db/migrate"))
      File.write(File.join(root, "db/migrate/20990101000000_future_change.rb"), "# frozen_string_literal: true\n")
      generator = migration_generator(root)
      generator.stub(:say, nil) { generator.copy_migrations }

      migrations = Dir[File.join(root, "db/migrate/*recording_studio_users*.rb")]
      assert_equal 3, migrations.size
      assert(migrations.all? { |path| File.basename(path).to_i > 20_990_101_000_000 })

      generator.stub(:say, nil) { generator.copy_migrations }
      assert_equal 3, Dir[File.join(root, "db/migrate/*recording_studio_users*.rb")].size
    end
  end

  private

  def with_temp_app
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "config/initializers"))
      yield root
    end
  end

  def install_generator(root, options = {})
    RecordingStudioUsers::Generators::InstallGenerator.new([], options, destination_root: root)
  end

  def migration_generator(root, options = {})
    RecordingStudioUsers::Generators::MigrationsGenerator.new([], options, destination_root: root)
  end
end
