# frozen_string_literal: true

require "test_helper"

class RecordingStudioUsersFoundationTest < ActiveSupport::TestCase
  AllowAllPolicy = Class.new do
    def allowed?(_action)
      true
    end
  end

  test "dummy app declares engine recordables" do
    assert RecordingStudio.validate_recordable_declarations!
    assert_includes RecordingStudio.root_recordable_types, "RecordingStudioUsers::UserRoot"
    assert_equal(
      ["RecordingStudioUsers::UserRoot"],
      RecordingStudio.allowed_parent_types_for("RecordingStudioUsers::Profile")
    )
  end

  test "provisioning is idempotent and creates one profile recording" do
    user = create_user

    first = RecordingStudioUsers::Services::ProvisionUser.call(
      user: user,
      actor: user,
      profile_attributes: { display_name: "Ada Lovelace" }
    )
    second = RecordingStudioUsers::Services::ProvisionUser.call(user: user, actor: user)

    assert_equal first.user_root, second.user_root
    assert_equal first.profile_recording, second.profile_recording
    assert_equal "Ada Lovelace", user.recording_studio_users_display_name
    assert_equal 1, RecordingStudioUsers::UserRoot.where(user: user).count
    assert_equal 1, RecordingStudioUsers::Profile.where(user_root: first.user_root).count
  end

  test "profile revision replaces the current snapshot and preserves history" do
    user = create_user
    provisioned = RecordingStudioUsers::Services::ProvisionUser.call(
      user: user,
      actor: user,
      profile_attributes: { display_name: "Before" }
    )
    original_profile = provisioned.profile

    revised_profile = RecordingStudioUsers::Services::ReviseProfile.call(
      user: user,
      actor: user,
      profile_attributes: { display_name: "After" },
      expected_profile_id: original_profile.id,
      event_metadata: { source: "test" }
    )

    assert_equal "After", revised_profile.display_name
    refute_equal original_profile.id, revised_profile.id
    assert_equal original_profile.id, provisioned.profile_recording.reload.events.first.previous_recordable_id
    assert_equal 2, RecordingStudioUsers::Profile.where(user_root: provisioned.user_root).count
    assert_raises(ActiveRecord::ReadOnlyRecord) { original_profile.update!(display_name: "Mutated") }
    assert_database_rejects_profile_mutation(original_profile)
  end

  test "lookups do not provision missing users" do
    user = create_user

    assert_nil RecordingStudioUsers.profile_for(user)
    assert_no_difference -> { RecordingStudioUsers::UserRoot.count } do
      assert_nil user.recording_studio_users_root_recording
    end
  end

  test "stale revisions and cross-user updates fail closed" do
    user = create_user
    other_user = create_user
    profile = RecordingStudioUsers::Services::ProvisionUser.call(user: user, actor: user).profile

    assert_raises(RecordingStudioUsers::StaleProfileError) do
      RecordingStudioUsers::Services::ReviseProfile.call(
        user: user,
        actor: user,
        profile_attributes: { display_name: "Rejected" },
        expected_profile_id: SecureRandom.uuid
      )
    end

    assert_raises(RecordingStudioUsers::UnauthorizedError) do
      RecordingStudioUsers::Services::ReviseProfile.call(
        user: user,
        actor: other_user,
        profile_attributes: { display_name: "Rejected" },
        expected_profile_id: profile.id
      )
    end
  end

  test "an unpersisted actor cannot impersonate a persisted user by id" do
    user = create_user
    profile = RecordingStudioUsers::Services::ProvisionUser.call(user: user, actor: user).profile
    forged_actor = User.new(id: user.id, email: user.email)

    assert_raises(RecordingStudioUsers::UnauthorizedError) do
      RecordingStudioUsers::Services::ProvisionUser.call(user: user, actor: forged_actor)
    end
    assert_raises(RecordingStudioUsers::UnauthorizedError) do
      RecordingStudioUsers::Services::ReviseProfile.call(
        user: user,
        actor: forged_actor,
        profile_attributes: { display_name: "Rejected" },
        expected_profile_id: profile.id
      )
    end
  end

  test "search returns active current profiles only" do
    original_resolver = RecordingStudioUsers.configuration.policy_resolver
    RecordingStudioUsers.configuration.policy_resolver = ->(**) { AllowAllPolicy.new }

    visible = provision_named_user("Search Visible")
    trashed_profile = provision_named_user("Search Hidden Profile")
    trashed_root = provision_named_user("Search Hidden Root")
    trashed_profile.profile_recording.update_column(:trashed_at, Time.current)
    trashed_root.root_recording.update_column(:trashed_at, Time.current)

    results = RecordingStudioUsers::Search::Profiles.call(
      actor: visible.user_root.user,
      query: "Search",
      limit: 10
    ).to_a

    assert_equal [visible.profile.id], results.map(&:id)
  ensure
    RecordingStudioUsers.configuration.policy_resolver = original_resolver
  end

  test "custom search results are re-scoped and limited" do
    original_resolver = RecordingStudioUsers.configuration.policy_resolver
    original_searcher = RecordingStudioUsers.configuration.profile_searcher
    RecordingStudioUsers.configuration.policy_resolver = ->(**) { AllowAllPolicy.new }

    first = provision_named_user("Custom Search One")
    second = provision_named_user("Custom Search Two")
    hidden = provision_named_user("Custom Search Hidden")
    hidden.profile_recording.update_column(:trashed_at, Time.current)
    candidate_ids = [first.profile.id, second.profile.id, hidden.profile.id]
    RecordingStudioUsers.configuration.profile_searcher = lambda do |**|
      RecordingStudioUsers::Profile.where(id: candidate_ids).order(:created_at)
    end

    results = RecordingStudioUsers::Search::Profiles.call(
      actor: first.user_root.user,
      query: "ignored by host searcher",
      limit: 2
    ).to_a

    assert_equal 2, results.size
    assert_equal [first.profile.id, second.profile.id].sort, results.map(&:id).sort
  ensure
    RecordingStudioUsers.configuration.policy_resolver = original_resolver
    RecordingStudioUsers.configuration.profile_searcher = original_searcher
  end

  private

  def create_user
    suffix = SecureRandom.hex(6)
    User.create!(
      email: "users-engine-#{suffix}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
  end

  def provision_named_user(display_name)
    user = create_user
    RecordingStudioUsers::Services::ProvisionUser.call(
      user: user,
      actor: user,
      profile_attributes: { display_name: display_name }
    )
  end

  def assert_database_rejects_profile_mutation(profile)
    assert_raises(ActiveRecord::StatementInvalid) do
      RecordingStudioUsers::Profile.transaction(requires_new: true) do
        RecordingStudioUsers::Profile.where(id: profile.id).update_all(display_name: "SQL mutation")
      end
    end
    assert_raises(ActiveRecord::StatementInvalid) do
      RecordingStudioUsers::Profile.transaction(requires_new: true) do
        RecordingStudioUsers::Profile.where(id: profile.id).delete_all
      end
    end
  end
end
