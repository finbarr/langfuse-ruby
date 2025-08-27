# frozen_string_literal: true

require 'langfuse/version'
require 'langfuse/configuration'

# Load models
require 'langfuse/models/ingestion_event'
require 'langfuse/models/trace'
require 'langfuse/models/span'
require 'langfuse/models/generation'
require 'langfuse/models/event'
require 'langfuse/models/score'
require 'langfuse/models/usage'

# Load API client
require 'langfuse/api_client'

# Load job adapter
require 'langfuse/job_adapter'

# Load main client
require 'langfuse/client'

module Langfuse
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= ::Langfuse::Configuration.new
    end

    # Configuration block
    def configure(&_block)
      # Pass the block to yield
      yield(configuration)
    end

    # --- Convenience delegators to the client instance ---

    # Create Trace
    def trace(attributes = {})
      Client.instance.trace(attributes)
    end

    # Create Span
    def span(attributes = {})
      Client.instance.span(attributes)
    end

    # Update Span
    def update_span(span)
      Client.instance.update_span(span)
      # Return void implicitly
    end

    # Create Generation
    def generation(attributes = {})
      Client.instance.generation(attributes)
    end

    # Update Generation
    def update_generation(generation)
      Client.instance.update_generation(generation)
      # Return void implicitly
    end

    # Create Event
    def event(attributes = {})
      Client.instance.event(attributes)
    end

    # Create Score
    def score(attributes = {})
      Client.instance.score(attributes)
    end

    # Flush events
    def flush
      Client.instance.flush
    end

    # Shutdown client
    def shutdown
      Client.instance.shutdown
    end
  end
end