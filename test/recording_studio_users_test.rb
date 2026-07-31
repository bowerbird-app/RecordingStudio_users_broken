# frozen_string_literal: true

require "test_helper"

class RecordingStudioUsersTest < Minitest::Test
  def test_version_is_present
    assert RecordingStudioUsers::VERSION
  end

  def test_user_class_defaults_to_user
    assert_equal "User", RecordingStudioUsers.configuration.user_class_name
  end

  def test_profile_attribute_filter_rejects_auth_fields
    error = assert_raises(ArgumentError) do
      RecordingStudioUsers.send(:sanitize_profile_attributes, email: "x@example.com")
    end

    assert_includes error.message, "Forbidden profile attributes"
  end
end
