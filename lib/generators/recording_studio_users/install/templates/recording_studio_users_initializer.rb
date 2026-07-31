# frozen_string_literal: true

RecordingStudioUsers.configure do |config|
  config.user_class_name = "User"
  config.registration_enabled = true
  config.default_locale = "en"
  config.default_time_zone = "UTC"
  config.picker_limit = 20

  config.provisioning_actor_resolver = lambda do |user:, actor: nil|
    actor || user
  end

  config.identity_visible_policy = lambda do |viewer:, user:, context: nil|
    viewer.present? && viewer == user
  end

  config.email_visible_policy = lambda do |viewer:, user:, context: nil|
    viewer.present? && viewer == user
  end

  config.profile_visible_policy = lambda do |viewer:, user:, context: nil|
    viewer.present? && viewer == user
  end

  config.profile_editable_policy = lambda do |viewer:, user:, context: nil|
    viewer.present? && viewer == user
  end
end
