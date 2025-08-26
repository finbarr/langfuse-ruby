# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: %i[spec rubocop]

desc 'Run tests with coverage'
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task['spec'].invoke
end

desc 'Open an interactive console with the gem loaded'
task :console do
  exec 'bundle exec bin/console'
end

desc 'Run Sorbet type checking'
task :typecheck do
  sh 'bundle exec srb tc'
end

desc 'Generate Sorbet RBI files'
task :tapioca do
  sh 'bundle exec tapioca init' unless File.exist?('sorbet/config')
  sh 'bundle exec tapioca gems'
end
