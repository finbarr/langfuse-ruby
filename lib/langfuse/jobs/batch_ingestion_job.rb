# frozen_string_literal: true
# typed: strict

require 'sorbet-runtime'

module Langfuse
  module Jobs
    # ActiveJob adapter for processing Langfuse events
    # This job can be used with any ActiveJob backend including Solid Queue
    class BatchIngestionJob < (defined?(ActiveJob) ? ActiveJob::Base : Object)
      extend T::Sig

      if defined?(ActiveJob)
        # Configure the job options
        queue_as :langfuse

        # Retry with exponential backoff
        retry_on StandardError, wait: :exponentially_longer, attempts: 5

        # Don't retry client errors (4xx except 429)
        discard_on ArgumentError

        sig { params(event_hashes: T::Array[T::Hash[T.untyped, T.untyped]]).void }
        def perform(event_hashes)
          api_client = T.unsafe(ApiClient).new(T.unsafe(Langfuse).configuration)

          response = api_client.ingest(event_hashes)

          # Check for partial failures
          errors = T.let(response['errors'], T.nilable(T::Array[T::Hash[String, T.untyped]]))
          handle_errors(errors, event_hashes) if errors&.any?
        rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED => e
          # Network errors - let ActiveJob retry
          Rails.logger.error("Langfuse network error: #{e.full_message}") if defined?(Rails)
          raise
        rescue StandardError => e
          # Check if it's a non-retryable error
          if e.message.include?('400') || e.message.include?('401') ||
             e.message.include?('403') || e.message.include?('404')
            # Don't retry client errors
            Rails.logger.error("Langfuse client error (not retrying): #{e.message}") if defined?(Rails)
            raise ArgumentError, e.message
          else
            # Other errors - let ActiveJob retry
            Rails.logger.error("Langfuse API error: #{e.message}") if defined?(Rails)
            raise
          end
        end

        private

        sig { params(errors: T::Array[T::Hash[String, T.untyped]], event_hashes: T::Array[T::Hash[T.untyped, T.untyped]]).void }
        def handle_errors(errors, event_hashes)
          errors.each do |error|
            Rails.logger.error("Langfuse API error for event #{error['id']}: #{error['message']}") if defined?(Rails)

            status = T.let(error['status'], T.untyped).to_i
            next unless non_retryable_error?(status)

            # Find and store the failed event
            failed_event = event_hashes.find { |e| T.unsafe(e)[:id] == error['id'] }
            store_failed_event(failed_event, error['message'].to_s) if failed_event
          end
        end

        sig { params(status: Integer).returns(T::Boolean) }
        def non_retryable_error?(status)
          # 4xx errors except 429 (rate limit) are not retryable
          status >= 400 && status < 500 && status != 429
        end

        sig { params(event: T::Hash[T.untyped, T.untyped], error_msg: String).void }
        def store_failed_event(event, error_msg)
          # Store failed events in Rails cache or database
          # This is a simpler implementation that works with any Rails cache store
          return unless defined?(Rails) && Rails.cache

          failed_events = Rails.cache.fetch('langfuse:failed_events', expires_in: 7.days) { [] }
          failed_events << {
            event: event,
            error: error_msg,
            timestamp: Time.now.utc.iso8601
          }
          Rails.cache.write('langfuse:failed_events', failed_events, expires_in: 7.days)
        end
      else
        # Fallback when ActiveJob is not available
        sig { params(event_hashes: T::Array[T::Hash[T.untyped, T.untyped]]).void }
        def self.perform_later(event_hashes)
          # Synchronous processing when ActiveJob is not available
          new.perform(event_hashes)
        end

        sig { params(event_hashes: T::Array[T::Hash[T.untyped, T.untyped]]).void }
        def perform(event_hashes)
          T.unsafe(ApiClient).new(T.unsafe(Langfuse).configuration).ingest(event_hashes)
        end
      end
    end
  end
end
