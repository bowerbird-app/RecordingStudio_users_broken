# frozen_string_literal: true

require "test_helper"

class RecordingStudioUsersTest < Minitest::Test
  TestUser = Struct.new(:id, :name, :email) do
    def persisted?
      id.present?
    end
  end
  IntegerIdUser = Struct.new(:id) do
    def persisted?
      true
    end

    def self.primary_key
      "id"
    end

    def self.type_for_attribute(_name)
      Struct.new(:type).new(:integer)
    end
  end

  def setup
    @original_configuration = RecordingStudioUsers.configuration
    RecordingStudioUsers.reset_configuration!
  end

  def teardown
    RecordingStudioUsers.instance_variable_set(:@configuration, @original_configuration)
  end

  def test_public_identity
    assert_equal "0.1.0", RecordingStudioUsers::VERSION
    assert_kind_of Class, RecordingStudioUsers::Engine
    assert_equal(
      %w[RecordingStudioUsers::UserRoot RecordingStudioUsers::Profile],
      RecordingStudioUsers::RECORDABLE_TYPES
    )
  end

  def test_default_policy_allows_only_same_user
    user = TestUser.new("user-id", "Ada", "ada@example.com")
    other_user = TestUser.new("other-id", "Grace", "grace@example.com")
    forged_user = TestUser.new("user-id", "Forged", "forged@example.com")
    forged_user.define_singleton_method(:persisted?) { false }

    assert RecordingStudioUsers::Policy.new(actor: user, user: user).allowed?(:show)
    assert RecordingStudioUsers::Policy.new(actor: user, user: user).allowed?(:update)
    refute RecordingStudioUsers::Policy.new(actor: other_user, user: user).allowed?(:show)
    refute RecordingStudioUsers::Policy.new(actor: forged_user, user: user).allowed?(:show)
    refute RecordingStudioUsers::Policy.new(actor: user, user: user).allowed?(:search)
    refute RecordingStudioUsers::Policy.new(actor: user, user: user).allowed?(:destroy)
  end

  def test_authorization_fails_closed_for_invalid_policy_contract
    user = TestUser.new("user-id", "Ada", "ada@example.com")
    RecordingStudioUsers.configure { |config| config.policy_resolver = ->(**) { Object.new } }

    assert_raises(RecordingStudioUsers::ContractError) do
      RecordingStudioUsers.policy_for(actor: user, user: user)
    end
  end

  def test_presentation_prefers_profile_then_configured_user_name
    user = TestUser.new("user-id", "Ada Lovelace", "ada@example.com")
    profile = Struct.new(:display_name).new("Countess Lovelace")

    RecordingStudioUsers.stub(:profile_for, profile) do
      assert_equal "Countess Lovelace", RecordingStudioUsers.display_name_for(user)
      assert_equal "CL", RecordingStudioUsers.initials_for(user)
    end

    RecordingStudioUsers.stub(:profile_for, nil) do
      assert_equal "Ada Lovelace", RecordingStudioUsers.display_name_for(user)
      assert_equal "AL", RecordingStudioUsers.initials_for(user)
    end
  end

  def test_profile_attribute_contract_rejects_unknown_and_invalid_metadata
    normalized = RecordingStudioUsers::Services::ProfileAttributes.normalize(
      "display_name" => "  Ada   Lovelace ",
      metadata: { theme: "dark" }
    )

    assert_equal "Ada Lovelace", normalized.fetch(:display_name)
    assert_equal({ "theme" => "dark" }, normalized.fetch(:metadata))
    assert_raises(RecordingStudioUsers::InvalidProfileAttributesError) do
      RecordingStudioUsers::Services::ProfileAttributes.normalize(admin: true)
    end
    assert_raises(RecordingStudioUsers::InvalidProfileAttributesError) do
      RecordingStudioUsers::Services::ProfileAttributes.normalize(metadata: "not an object")
    end
  end

  def test_unsupported_integrations_raise_exact_errors
    accessible_error = assert_raises(RecordingStudioUsers::IntegrationUnavailableError) do
      RecordingStudioUsers::Integrations::Accessible.grant_first_access!
    end
    attachable_error = assert_raises(RecordingStudioUsers::IntegrationUnavailableError) do
      RecordingStudioUsers::Integrations::Attachable.install_profile_avatar!
    end

    assert_includes accessible_error.message, "no public first-grant/bootstrap API"
    assert_includes attachable_error.message, "no public singleton attachment"
  end

  def test_provisioning_rejects_non_uuid_host_users_before_writing
    service = RecordingStudioUsers::Services::ProvisionUser.new(
      user: IntegerIdUser.new(123),
      actor: nil
    )

    error = assert_raises(RecordingStudioUsers::ConfigurationError) do
      service.send(:validate_user!)
    end
    assert_includes error.message, "requires a UUID primary key"
  end
end
