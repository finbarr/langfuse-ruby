# frozen_string_literal: true

require_relative 'lib/langfuse/version'

Gem::Specification.new do |spec|
  spec.name          = 'langfuse-ruby'
  spec.version       = Langfuse::VERSION
  spec.authors       = ['Finbarr Taylor']
  spec.email         = ['finbarrtaylor@gmail.com']

  spec.summary       = 'Ruby SDK for Langfuse observability platform'
  spec.description   = 'A Ruby client for the Langfuse observability platform. Fork of the original langfuse gem with bug fixes and improvements.'
  spec.homepage      = 'https://github.com/finbarr/langfuse-ruby'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/finbarr/langfuse-ruby'
  spec.metadata['changelog_uri'] = 'https://github.com/finbarr/langfuse-ruby/blob/master/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'concurrent-ruby', '~> 1.2'

  # Development dependencies
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rubocop', '~> 1.50'
  spec.add_development_dependency 'rubocop-rake', '~> 0.6'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.22'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'webmock', '~> 3.18'
  spec.add_development_dependency 'yard', '~> 0.9'

  # Optional dependencies (for Sidekiq support)
  spec.add_development_dependency 'sidekiq', '~> 7.0'
end
