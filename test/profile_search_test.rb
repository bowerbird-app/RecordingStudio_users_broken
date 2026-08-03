# frozen_string_literal: true

require "test_helper"

class ProfileSearchTest < Minitest::Test
  FakeRelation = Struct.new(:applied_limit, :applied_where) do
    def limit(value)
      self.applied_limit = value
      self
    end

    def none
      []
    end

    def where(conditions)
      self.applied_where = conditions
      self
    end

    def to_a
      []
    end
  end

  AllowSearchPolicy = Struct.new(:allowed) do
    def allowed?(action)
      action == :search && allowed
    end
  end

  def setup
    @original_configuration = RecordingStudioUsers.configuration
    RecordingStudioUsers.reset_configuration!
  end

  def teardown
    RecordingStudioUsers.instance_variable_set(:@configuration, @original_configuration)
  end

  def test_search_is_denied_by_default_before_querying
    assert_raises(RecordingStudioUsers::UnauthorizedError) do
      RecordingStudioUsers::Search::Profiles.call(actor: Object.new, query: "Ada")
    end
  end

  def test_custom_search_contract_receives_normalized_bounded_inputs
    relation = FakeRelation.new
    received = nil
    RecordingStudioUsers.configure do |config|
      config.policy_resolver = ->(**) { AllowSearchPolicy.new(true) }
      config.profile_searcher = lambda do |query:, relation:, limit:|
        received = [query, relation, limit]
        []
      end
    end

    result = RecordingStudioUsers::Search::Profiles.stub(:current_profiles, relation) do
      RecordingStudioUsers::Search::Profiles.call(actor: Object.new, query: "  Ada   Love ", limit: 12)
    end

    assert_same relation, result
    assert_equal ["Ada Love", relation, 12], received
    assert_equal 12, relation.applied_limit
    assert_equal({ id: [] }, relation.applied_where)
  end

  def test_search_rejects_unbounded_or_invalid_contract_results
    relation = FakeRelation.new
    RecordingStudioUsers.configure do |config|
      config.policy_resolver = ->(**) { AllowSearchPolicy.new(true) }
      config.profile_searcher = ->(**) { Object.new }
    end

    assert_raises(RecordingStudioUsers::ContractError) do
      RecordingStudioUsers::Search::Profiles.stub(:current_profiles, relation) do
        RecordingStudioUsers::Search::Profiles.call(actor: Object.new, query: "x", limit: 101)
      end
    end

    assert_raises(RecordingStudioUsers::ContractError) do
      RecordingStudioUsers::Search::Profiles.stub(:current_profiles, relation) do
        RecordingStudioUsers::Search::Profiles.call(actor: Object.new, query: "x", limit: 10)
      end
    end
  end
end
