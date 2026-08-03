# frozen_string_literal: true

require "test_helper"

class EngineTest < Minitest::Test
  def test_register_recordables_uses_public_recording_studio_api
    registered = []

    register = ->(type) { registered << type }
    RecordingStudio.stub(:register_recordable_type, register) do
      RecordingStudio.stub(:recordable_declaration_defined?, true) do
        RecordingStudioUsers.register_recordables!
      end
    end

    assert_equal RecordingStudioUsers::RECORDABLE_TYPES, registered
  end

  def test_register_recordables_fails_when_own_declaration_is_missing
    RecordingStudio.stub(:register_recordable_type, nil) do
      RecordingStudio.stub(:recordable_declaration_defined?, false) do
        error = assert_raises(RecordingStudioUsers::ConfigurationError) do
          RecordingStudioUsers.register_recordables!
        end

        assert_includes error.message, "RecordingStudioUsers::Profile"
      end
    end
  end

  def test_engine_is_isolated_and_data_only
    assert_equal "recording_studio_users", RecordingStudioUsers::Engine.engine_name
    assert_empty RecordingStudioUsers::Engine.routes.routes
  end
end
