# frozen_string_literal: true

require_relative "lib/recording_studio_users/version"

Gem::Specification.new do |spec|
  spec.name        = "recording_studio_users"
  spec.version     = RecordingStudioUsers::VERSION
  spec.authors     = ["Bowerbird"]
  spec.homepage    = "https://github.com/bowerbird-app/RecordingStudio_users"
  spec.summary     = "Users engine for the RecordingStudio ecosystem"
  spec.description = "Rails engine for user provisioning, profile revisions, identity helpers, and avatar integration in RecordingStudio apps"
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bowerbird-app/RecordingStudio_users"
  spec.metadata["changelog_uri"] = "https://github.com/bowerbird-app/RecordingStudio_users/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "devise"
  spec.add_dependency "rails", "~> 8.1.0"
end
