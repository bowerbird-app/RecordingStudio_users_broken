# frozen_string_literal: true

require "minitest/autorun"

class RenameVerificationTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  GEM_NAME = "recording_studio_users"
  NAMESPACE = "RecordingStudioUsers"

  def test_canonical_files_and_directories_exist
    expected = [
      "#{GEM_NAME}.gemspec",
      "lib/#{GEM_NAME}.rb",
      "lib/#{GEM_NAME}/version.rb",
      "lib/#{GEM_NAME}/engine.rb",
      "lib/generators/#{GEM_NAME}/install/install_generator.rb",
      "app/models/#{GEM_NAME}/user_root.rb",
      "app/models/#{GEM_NAME}/profile.rb"
    ]

    missing = expected.reject { |path| File.exist?(File.join(ROOT, path)) }
    assert_empty missing, "Missing renamed files: #{missing.join(', ')}"
  end

  def test_gemspec_and_entrypoint_use_canonical_identity
    gemspec = File.read(File.join(ROOT, "#{GEM_NAME}.gemspec"))
    entrypoint = File.read(File.join(ROOT, "lib/#{GEM_NAME}.rb"))

    assert_includes gemspec, %(spec.name        = "#{GEM_NAME}")
    assert_includes gemspec, "#{NAMESPACE}::VERSION"
    assert_match(/^module #{NAMESPACE}$/, entrypoint)
    assert_includes entrypoint, %(require "#{GEM_NAME}/engine")
  end

  def test_legacy_template_identity_is_absent
    legacy_snake = %w[gem template].join("_")
    legacy_constant = %w[Gem Template].join
    roots = %w[app config db docs lib].map { |path| File.join(ROOT, path) }
    files = roots.flat_map { |root| Dir.glob(File.join(root, "**/*")) }.select { |path| File.file?(path) }

    offenders = files.select do |path|
      content = File.binread(path)
      content.include?(legacy_snake) || content.include?(legacy_constant)
    rescue ArgumentError
      false
    end

    assert_empty offenders, "Legacy identity remains in: #{offenders.join(', ')}"
  end

  def test_runtime_identity_loads
    $LOAD_PATH.unshift(File.join(ROOT, "lib")) unless $LOAD_PATH.include?(File.join(ROOT, "lib"))
    require "#{GEM_NAME}/version"

    assert_equal "0.1.0", Object.const_get(NAMESPACE)::VERSION
  end
end
