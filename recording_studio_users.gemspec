# frozen_string_literal: true

require_relative "lib/recording_studio_users/version"

Gem::Specification.new do |spec|
  spec.name        = "recording_studio_users"
  spec.version     = RecordingStudioUsers::VERSION
  spec.authors     = ["Bowerbird"]
  spec.email       = ["opensource@bowerbird.app"]
  spec.homepage    = "https://github.com/bowerbird-app/RecordingStudio_users"
  spec.summary     = "Append-only user profiles for Recording Studio"
  spec.description = "A Rails engine that gives host users a UUID Recording Studio root, " \
                     "immutable profile snapshots, safe lookup and presentation contracts, " \
                     "and explicit optional integrations."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", "~> 8.1.0"
  spec.add_dependency "recording_studio", "~> 3.0"
end
