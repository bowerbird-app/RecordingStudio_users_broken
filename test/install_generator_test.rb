# frozen_string_literal: true

require "test_helper"
require "generators/recording_studio_users/install/install_generator"

class InstallGeneratorTest < Minitest::Test
  def build_generator(destination_root, options = {})
    RecordingStudioUsers::Generators::InstallGenerator.new([], options, destination_root: destination_root)
  end

  def test_mount_engine_uses_configured_mount_path
    generator = build_generator("/tmp", mount_path: "/addons/users")
    routes = []

    generator.stub(:route, ->(value) { routes << value }) do
      generator.mount_engine
    end

    assert_equal ["mount RecordingStudioUsers::Engine, at: \"/addons/users\""], routes
  end

  def test_install_guide_mentions_backfill
    path = File.expand_path("../lib/generators/recording_studio_users/install/templates/INSTALL.md", __dir__)
    content = File.read(path)

    assert_includes content, "recording_studio_users:backfill_profiles"
  end
end
