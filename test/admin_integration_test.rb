# frozen_string_literal: true

require "test_helper"

class AdminIntegrationTest < Minitest::Test
  class FakeResource
    class << self
      attr_reader :key_value, :title_value, :section_value

      def key(value)
        @key_value = value
      end

      def title(value)
        @title_value = value
      end

      def section(value)
        @section_value = value
      end
    end
  end

  def setup
    @original_configuration = RecordingStudioUsers.configuration
    RecordingStudioUsers.reset_configuration!
  end

  def teardown
    RecordingStudioUsers.send(:remove_const, :Admin) if RecordingStudioUsers.const_defined?(:Admin, false)
    Object.send(:remove_const, :RecordingStudioAdmin) if Object.const_defined?(:RecordingStudioAdmin, false)
    RecordingStudioUsers.instance_variable_set(:@configuration, @original_configuration)
  end

  def test_registration_fails_clearly_without_public_admin_api
    error = assert_raises(RecordingStudioUsers::IntegrationUnavailableError) do
      RecordingStudioUsers::Integrations::Admin.register!
    end

    assert_includes error.message, "public Resource and register_resource APIs"
  end

  def test_registration_uses_public_resource_registry
    admin = Module.new
    admin.const_set(:Resource, FakeResource)
    registered = []
    admin.define_singleton_method(:register_resource) do |resource|
      registered << resource
      resource
    end
    Object.const_set(:RecordingStudioAdmin, admin)

    RecordingStudioUsers.configure { |config| config.admin_section_key = "people" }
    resource = RecordingStudioUsers::Integrations::Admin.register!

    assert_equal [resource], registered
    assert_equal "recording_studio_users", resource.key_value
    assert_equal "Users", resource.title_value
    assert_equal "people", resource.section_value
  end
end
