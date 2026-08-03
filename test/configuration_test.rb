# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    @configuration = RecordingStudioUsers::Configuration.new
  end

  def test_safe_defaults
    assert_equal "User", @configuration.user_class_name
    assert_equal 25, @configuration.profile_search_limit
    assert_equal "users", @configuration.admin_section_key
    refute @configuration.register_admin_resource
    refute @configuration.to_h.fetch(:custom_user_loader)
    refute @configuration.to_h.fetch(:custom_profile_searcher)
  end

  def test_search_limit_is_bounded
    @configuration.profile_search_limit = 100

    assert_equal 100, @configuration.profile_search_limit
    assert_raises(RecordingStudioUsers::ConfigurationError) { @configuration.profile_search_limit = 0 }
    assert_raises(RecordingStudioUsers::ConfigurationError) { @configuration.profile_search_limit = 101 }
    assert_raises(RecordingStudioUsers::ConfigurationError) { @configuration.profile_search_limit = "many" }
  end

  def test_callable_contracts_are_validated
    assert_raises(RecordingStudioUsers::ConfigurationError) { @configuration.policy_resolver = Object.new }
    assert_raises(RecordingStudioUsers::ConfigurationError) { @configuration.user_loader = Object.new }
    assert_raises(RecordingStudioUsers::ConfigurationError) { @configuration.profile_searcher = Object.new }
    assert_raises(RecordingStudioUsers::ConfigurationError) { @configuration.user_name_resolver = Object.new }

    @configuration.user_loader = ->(id:) { id }
    @configuration.profile_searcher = ->(**) { [] }

    assert @configuration.to_h.fetch(:custom_user_loader)
    assert @configuration.to_h.fetch(:custom_profile_searcher)
  end

  def test_constant_and_admin_keys_are_restricted
    assert_raises(RecordingStudioUsers::ConfigurationError) { @configuration.user_class_name = "../../User" }
    assert_raises(RecordingStudioUsers::ConfigurationError) { @configuration.admin_section_key = "Users Area" }
    assert_raises(RecordingStudioUsers::ConfigurationError) { @configuration.register_admin_resource = "true" }

    @configuration.user_class_name = "Accounts::User"
    @configuration.admin_section_key = "account_users"
    @configuration.register_admin_resource = true

    assert_equal "Accounts::User", @configuration.user_class_name
    assert @configuration.register_admin_resource
  end

  def test_merge_is_strict_about_unknown_keys
    @configuration.merge!(profile_search_limit: 10)

    assert_equal 10, @configuration.profile_search_limit
    assert_raises(RecordingStudioUsers::ConfigurationError) { @configuration.merge!(unknown: true) }
    assert_raises(RecordingStudioUsers::ConfigurationError) { @configuration.merge!(nil) }
  end
end
