# frozen_string_literal: true

module RecordingStudioUsers
  Avatar = Struct.new(:image_path, :initials, :alt_text, :width, :height, keyword_init: true) do
    def image?
      image_path.present?
    end
  end
end
