# frozen_string_literal: true

require "test_helper"

class UserLoaderTest < Minitest::Test
  class LoaderUser
    attr_reader :id

    def initialize(id)
      @id = id
    end

    class << self
      attr_accessor :records

      def find_by(id:)
        records&.fetch(id, nil)
      end
    end
  end

  def setup
    @original_configuration = RecordingStudioUsers.configuration
    RecordingStudioUsers.reset_configuration!
    RecordingStudioUsers.configure { |config| config.user_class_name = self.class::LoaderUser.name }
    LoaderUser.records = { "known" => LoaderUser.new("known") }
  end

  def teardown
    RecordingStudioUsers.instance_variable_set(:@configuration, @original_configuration)
  end

  def test_default_loader_uses_configured_class_without_constantizing_input
    assert_equal "known", RecordingStudioUsers.load_user(id: " known ").id
    assert_nil RecordingStudioUsers.load_user(id: "")
    assert_nil RecordingStudioUsers.load_user(id: "missing")
  end

  def test_custom_loader_receives_keyword_and_must_return_configured_class
    seen = nil
    RecordingStudioUsers.configure do |config|
      config.user_loader = lambda do |id:|
        seen = id
        LoaderUser.new(id)
      end
    end

    assert_equal "custom", RecordingStudioUsers.load_user(id: "custom").id
    assert_equal "custom", seen

    RecordingStudioUsers.configure { |config| config.user_loader = ->(id:) { id } }
    assert_raises(RecordingStudioUsers::ContractError) { RecordingStudioUsers.load_user(id: "wrong") }
  end

  def test_identifier_is_bounded_and_rejects_control_characters
    assert_raises(RecordingStudioUsers::ContractError) do
      RecordingStudioUsers.load_user(id: "x" * 256)
    end
    assert_raises(RecordingStudioUsers::ContractError) do
      RecordingStudioUsers.load_user(id: "bad\u0000id")
    end
  end
end
