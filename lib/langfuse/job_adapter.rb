# frozen_string_literal: true
# typed: strict

require 'sorbet-runtime'

module Langfuse
  # Adapter to handle different job processing backends
  class JobAdapter
    extend T::Sig
    
    sig { returns(Symbol) }
    attr_reader :backend
    
    sig { params(backend: T.nilable(Symbol)).void }
    def initialize(backend = nil)
      @backend = T.let(detect_backend(backend), Symbol)
    end
    
    sig { params(event_hashes: T::Array[T::Hash[T.untyped, T.untyped]]).void }
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
    
    sig { params(backend: T.nilable(Symbol)).returns(Symbol) }
    def detect_backend(backend)
      return backend if backend
      
      # Auto-detect available backend
      if defined?(ActiveJob)
        :active_job
      elsif defined?(Sidekiq)
        :sidekiq
      else
        :synchronous
      end
    end
    
    sig { params(event_hashes: T::Array[T::Hash[T.untyped, T.untyped]]).void }
    def enqueue_sidekiq(event_hashes)
      require 'langfuse/batch_worker'
      T.unsafe(BatchWorker).perform_async(event_hashes)
    end
    
    sig { params(event_hashes: T::Array[T::Hash[T.untyped, T.untyped]]).void }
    def enqueue_active_job(event_hashes)
      require 'langfuse/jobs/batch_ingestion_job'
      T.unsafe(Jobs::BatchIngestionJob).perform_later(event_hashes)
    end
    
    sig { params(event_hashes: T::Array[T::Hash[T.untyped, T.untyped]]).void }
    def enqueue_synchronous(event_hashes)
      # Direct synchronous processing
      T.unsafe(ApiClient).new(T.unsafe(Langfuse).configuration).ingest(event_hashes)
    end
  end
end