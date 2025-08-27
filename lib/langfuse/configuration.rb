# frozen_string_literal: true

require 'logger'

module Langfuse
  class Configuration
    attr_accessor :public_key, :secret_key, :host, :batch_size, :flush_interval, :shutdown_timeout, :debug,
                  :disable_at_exit_hook, :logger, :job_backend, :queue_name

    def initialize
      # Default configuration with environment variable fallbacks
      @public_key = ENV.fetch('LANGFUSE_PUBLIC_KEY', nil)
      @secret_key = ENV.fetch('LANGFUSE_SECRET_KEY', nil)
      @host = ENV.fetch('LANGFUSE_HOST', 'https://us.cloud.langfuse.com')
      @batch_size = ENV.fetch('LANGFUSE_BATCH_SIZE', '10').to_i
      @flush_interval = ENV.fetch('LANGFUSE_FLUSH_INTERVAL', '60').to_i
      @debug = ENV.fetch('LANGFUSE_DEBUG', 'false') == 'true'
      @disable_at_exit_hook = false
      @shutdown_timeout = ENV.fetch('LANGFUSE_SHUTDOWN_TIMEOUT', '5').to_i
      @logger = Logger.new($stdout)

      # Job backend: :sidekiq, :active_job, :synchronous, or nil for auto-detect
      job_backend_env = ENV.fetch('LANGFUSE_JOB_BACKEND', nil)
      @job_backend = job_backend_env&.to_sym

      # Queue name for job processing (defaults to 'langfuse')
      @queue_name = ENV.fetch('LANGFUSE_QUEUE_NAME', 'langfuse')
    end
  end
end
