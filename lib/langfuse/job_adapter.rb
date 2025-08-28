# frozen_string_literal: true

module Langfuse
  # Adapter to handle different job processing backends
  class JobAdapter
    attr_reader :backend

    def initialize(backend = nil)
      @backend = backend || Langfuse.configuration.job_backend || :synchronous
    end

    def enqueue(event_hashes)
      case @backend
      when :sidekiq
        enqueue_sidekiq(event_hashes)
      when :active_job
        enqueue_active_job(event_hashes)
      when :synchronous
        enqueue_synchronous(event_hashes)
      else
        raise ArgumentError, "Unknown job backend: #{@backend}"
      end
    end

    private

    def enqueue_sidekiq(event_hashes)
      unless defined?(Langfuse::BatchWorker)
        raise "Sidekiq support not loaded. Add: require 'langfuse-ruby/sidekiq' to your code"
      end

      Langfuse::BatchWorker.perform_async(event_hashes)
    end

    def enqueue_active_job(event_hashes)
      unless defined?(Langfuse::Jobs::BatchIngestionJob)
        raise "ActiveJob support not loaded. Add: require 'langfuse-ruby/active_job' to your code"
      end

      Langfuse::Jobs::BatchIngestionJob.perform_later(event_hashes)
    end

    def enqueue_synchronous(event_hashes)
      # Direct synchronous processing
      ApiClient.new(Langfuse.configuration).ingest(event_hashes)
    end
  end
end
