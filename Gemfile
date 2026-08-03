# frozen_string_literal: true

source "https://rubygems.org"

# RecordingStudio is not published to RubyGems. Keep the verified source explicit
# for development while the gemspec preserves the normal runtime dependency.
gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v3.0.3"

# Specify the engine's dependencies in recording_studio_users.gemspec.
gem "devise"
gemspec

gem "puma"
gem "sprockets-rails"

group :development, :test do
  gem "debug"
  gem "simplecov", require: false
end

group :development do
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
end
