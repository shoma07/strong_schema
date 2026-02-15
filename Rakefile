# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new(:lint) do |t|
  t.options = ["--parallel"]
end

require "steep/rake_task"

Steep::RakeTask.new(:typecheck) do |t|
  t.check.severity_level = :error
  t.watch.verbose
end

namespace :rbs do
  desc "Generated RBS files from rbs-inline"
  task :inline do
    require "rbs/inline"
    require "rbs/inline/cli"
    io = StringIO.new
    RBS::Inline::CLI.new(stdout: io).run(%w[lib --opt-out])
    result = io.tap(&:rewind)
               .each_line.grep_v(/\A[[:blank:]]*#/).join
               .sub(/\A(?:[[:blank:]]*\n)+/, "")
               .sub(/(?:\n[[:blank:]]*)+\z/, "\n")
    File.write("sig/strong_schema.rbs", result)
  end
end

task default: %i[rbs:inline typecheck spec lint]
