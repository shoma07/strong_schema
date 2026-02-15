# frozen_string_literal: true

require_relative "lib/strong_schema/version"

Gem::Specification.new do |spec|
  spec.name = "strong_schema"
  spec.version = StrongSchema::VERSION
  spec.authors = ["shoma07"]
  spec.email = ["23730734+shoma07@users.noreply.github.com"]

  spec.summary = "Safety checks for declarative database schema changes"
  spec.description = "Adds safety checks to declarative schema operations in ActiveRecord::Schema."
  spec.homepage = "https://github.com/shoma07/strong_schema"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "strong_migrations", ">= 1.8"
end
