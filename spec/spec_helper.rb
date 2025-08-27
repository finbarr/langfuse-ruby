# frozen_string_literal: true

require 'simplecov'
if ENV['COVERAGE']
  SimpleCov.start do
    add_filter '/spec/'
    add_filter '/vendor/'
  end
end

require 'bundler/setup'

require 'langfuse'
require 'webmock/rspec'

# Load support files
Dir[File.expand_path('support/**/*.rb', __dir__)].sort.each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    # Reset configuration before each test
    Langfuse.configuration = Langfuse::Configuration.new

    # Set test credentials
    Langfuse.configure do |c|
      c.public_key = 'test-public-key'
      c.secret_key = 'test-secret-key'
      c.host = 'https://test.langfuse.com'
      c.debug = false
    end
  end

  config.after do
    # Clean up after each test
    WebMock.reset!
  end
end
