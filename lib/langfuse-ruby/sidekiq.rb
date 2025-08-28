# frozen_string_literal: true

require 'langfuse'

begin
  require 'sidekiq'
rescue LoadError
  raise 'Sidekiq is not available. Please add sidekiq to your Gemfile.'
end

module Langfuse
  class BatchWorker
    include Sidekiq::Worker

    sidekiq_options queue: proc { Langfuse.configuration.queue_name }, retry: 5, backtrace: true

    sidekiq_retry_in do |count|
      10 * (count + 1) # 10s, 20s, 30s, 40s, 50s
    end

    def perform(event_hashes)
      api_client = Langfuse::ApiClient.new(Langfuse.configuration)

      begin
        response = api_client.ingest(event_hashes)

        errors = response['errors']
        if errors&.any?
          errors.each do |error|
            logger.error("Langfuse API error for event #{error['id']}: #{error['message']}")

            status = error['status'].to_i
            next unless non_retryable_error?(status)

            failed_event = event_hashes.find { |e| e[:id] == error['id'] }
            store_failed_event(failed_event, error['message'].to_s) if failed_event
          end
        end
      rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED => e
        logger.error("Langfuse network error: #{e.full_message}")
        raise
      rescue StandardError => e
        logger.error("Langfuse API error: #{e.message}")
        raise
      end
    end

    private

    def non_retryable_error?(status)
      status >= 400 && status < 500 && status != 429
    end

    def store_failed_event(event, error_msg)
      Sidekiq.redis do |redis|
        redis.rpush('langfuse:failed_events', {
          event: event,
          error: error_msg,
          timestamp: Time.now.utc.iso8601
        }.to_json)
      end
    end
  end
end

# Set the job backend to sidekiq
Langfuse.configuration.job_backend = :sidekiq
