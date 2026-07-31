# frozen_string_literal: true

module RecordingStudioUsersHelper
  def recording_studio_user_name(user, context: nil)
    RecordingStudioUsers.display_name(user, context: context || { actor: current_user_if_available })
  end

  def recording_studio_user_avatar(user, size: :small, context: nil, html_options: {})
    avatar = RecordingStudioUsers.avatar_for(user, size: size, context: context || { actor: current_user_if_available })

    if avatar.image?
      image_tag(avatar.image_path, {
        alt: avatar.alt_text,
        width: avatar.width,
        height: avatar.height,
        class: "recording-studio-user-avatar"
      }.merge(html_options))
    else
      content_tag(:span, avatar.initials, {
        class: "recording-studio-user-avatar recording-studio-user-avatar--fallback",
        "aria-label": avatar.alt_text
      }.merge(html_options))
    end
  end

  def recording_studio_user_identity(user, show_email: false, context: nil)
    actor = context&.dig(:actor) || current_user_if_available
    name = RecordingStudioUsers.display_name(user, context: context || { actor: actor })

    detail = nil
    if show_email && RecordingStudioUsers.email_visible?(viewer: actor, user: user, context: context)
      detail = user.email
    end

    [name, detail].compact.join(" · ")
  end

  private

  def current_user_if_available
    current_user if respond_to?(:current_user)
  end
end
