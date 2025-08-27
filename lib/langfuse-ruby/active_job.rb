# frozen_string_literal: true

require 'langfuse'

begin
  require 'active_job'
rescue LoadError
  raise 'ActiveJob is not available. Please add activejob or rails to your Gemfile.'
end

module Langfuse
  module Jobs
    class BatchIngestionJob < ActiveJob::Base
      queue_as { Langfuse.configuration.queue_name.to_sym }
      
      retry_on StandardError, wait: :exponentially_longer, attempts: 5
      discard_on ArgumentError

      def perform(event_hashes)
        api_client = Langfuse::ApiClient.new(Langfuse.configuration)
        
        begin
          response = api_client.ingest(event_hashes)
          
          errors = response['errors']
          handle_errors(errors, event_hashes) if errors&.any?
        rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED => e
          Rails.logger.error("Langfuse network error: #{e.full_message}") if defined?(Rails)
          raise
        rescue StandardError => e
          if e.message.include?('400') || e.message.include?('401') ||
             e.message.include?('403') || e.message.include?('404')
            Rails.logger.error("Langfuse client error (not retrying): #{e.message}") if defined?(Rails)
            raise ArgumentError, e.message
          else
            Rails.logger.error("Langfuse API error: #{e.message}") if defined?(Rails)
            raise
          end
        end
      end

      private

      def handle_errors(errors, event_hashes)
        errors.each do |error|
          Rails.logger.error("Langfuse API error for event #{error['id']}: #{error['message']}") if defined?(Rails) && Rails.respond_to?(:logger)

          status = error['status'].to_i
          next unless non_retryable_error?(status)

          failed_event = event_hashes.find { |e| e[:id] == error['id'] }
          store_failed_event(failed_event, error['message'].to_s) if failed_event
        end
      end

      def non_retryable_error?(status)
        status >= 400 && status < 500 && status != 429
      end

      def store_failed_event(event, error_msg)
        return unless defined?(Rails) && Rails.respond_to?(:cache) && Rails.cache

        failed_events = Rails.cache.fetch('langfuse:failed_events', expires_in: 7.days) { [] }
        failed_events << {
          event: event,
          error: error_msg,
          timestamp: Time.now.utc.iso8601
        }
        Rails.cache.write('langfuse:failed_events', failed_events, expires_in: 7.days)
      end
    end
  end
end

# Set the job backend to active_job
Langfuse.configuration.job_backend = :active_job