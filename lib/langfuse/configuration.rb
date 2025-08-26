# frozen_string_literal: true
# typed: strict

require 'logger'
require 'sorbet-runtime'

module Langfuse
  class Configuration
    extend T::Sig

    sig { returns(T.nilable(String)) }
    attr_accessor :public_key, :secret_key

    sig { returns(String) }
    attr_accessor :host

    sig { returns(Integer) }
    attr_accessor :batch_size, :flush_interval, :shutdown_timeout

    sig { returns(T::Boolean) }
    attr_accessor :debug, :disable_at_exit_hook

    sig { returns(T.untyped) }
    attr_accessor :logger
    
    sig { returns(T.nilable(Symbol)) }
    attr_accessor :job_backend

    sig { void }
    def initialize
      # Default configuration with environment variable fallbacks
      @public_key = T.let(ENV.fetch('LANGFUSE_PUBLIC_KEY', nil), T.nilable(String))
      @secret_key = T.let(ENV.fetch('LANGFUSE_SECRET_KEY', nil), T.nilable(String))
      @host = T.let(ENV.fetch('LANGFUSE_HOST', 'https://us.cloud.langfuse.com'), String)
      @batch_size = T.let(ENV.fetch('LANGFUSE_BATCH_SIZE', '10').to_i, Integer)
      @flush_interval = T.let(ENV.fetch('LANGFUSE_FLUSH_INTERVAL', '60').to_i, Integer)
      @debug = T.let(ENV.fetch('LANGFUSE_DEBUG', 'false') == 'true', T::Boolean)
      @disable_at_exit_hook = T.let(false, T::Boolean)
      @shutdown_timeout = T.let(ENV.fetch('LANGFUSE_SHUTDOWN_TIMEOUT', '5').to_i, Integer)
      @logger = T.let(Logger.new($stdout), Logger)
      
      # Job backend: :sidekiq, :active_job, :synchronous, or nil for auto-detect
      job_backend_env = ENV.fetch('LANGFUSE_JOB_BACKEND', nil)
      @job_backend = T.let(job_backend_env&.to_sym, T.nilable(Symbol))
    end
  end
end
