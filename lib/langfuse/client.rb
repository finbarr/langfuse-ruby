# frozen_string_literal: true

require 'singleton'
require 'concurrent'
require 'logger'

# Model requires are implicitly handled by the main langfuse.rb require
# No need for placeholder type aliases here

module Langfuse
  class Client
    include Singleton

    attr_reader :config, :events, :flush_thread, :job_adapter

    def initialize
      @config = Langfuse.configuration

      # Validate required configuration
      validate_configuration!

      @events = Concurrent::Array.new
      @mutex = Mutex.new
      @flush_thread = nil

      # Initialize job adapter
      require 'langfuse/job_adapter'
      @job_adapter = JobAdapter.new(@config.job_backend)

      schedule_periodic_flush

      # Register shutdown hook
      return if @config.disable_at_exit_hook

      Kernel.at_exit { shutdown }
    end

    # Creates a new trace
    def trace(attributes = {})
      trace = Models::Trace.new(attributes)
      event = Models::IngestionEvent.new(
        type: 'trace-create',
        body: trace
      )
      enqueue_event(event)
      trace
    end

    # Creates a new span within a trace
    # The type parameter allows creating different observation types (SPAN, TOOL, AGENT, etc.)
    def span(attributes = {})
      raise ArgumentError, 'trace_id is required for creating a span' unless attributes[:trace_id]

      span = Models::Span.new(attributes)
      event = Models::IngestionEvent.new(
        type: 'span-create',
        body: span
      )
      enqueue_event(event)
      span
    end

    # Updates an existing span
    def update_span(span)
      # Assuming span object has :id and :trace_id methods/attributes
      unless span.id && span.trace_id
        raise ArgumentError,
              'span.id and span.trace_id are required for updating a span'
      end

      event = Models::IngestionEvent.new(
        type: 'span-update',
        body: span
      )
      enqueue_event(event)
      span
    end

    # Creates a new generation within a trace
    def generation(attributes = {})
      raise ArgumentError, 'trace_id is required for creating a generation' unless attributes[:trace_id]

      generation = Models::Generation.new(attributes)
      event = Models::IngestionEvent.new(
        type: 'generation-create',
        body: generation
      )
      enqueue_event(event)
      generation
    end

    # Updates an existing generation
    def update_generation(generation)
      unless generation.id && generation.trace_id
        raise ArgumentError, 'generation.id and generation.trace_id are required for updating a generation'
      end

      event = Models::IngestionEvent.new(
        type: 'generation-update',
        body: generation
      )
      enqueue_event(event)
      generation
    end

    # Creates a new event within a trace
    def event(attributes = {})
      raise ArgumentError, 'trace_id is required for creating an event' unless attributes[:trace_id]

      event_obj = Models::Event.new(attributes)
      event = Models::IngestionEvent.new(
        type: 'event-create',
        body: event_obj
      )
      enqueue_event(event)
      event_obj
    end

    # Creates a generic observation (can be SPAN, GENERATION, or EVENT)
    def observation(attributes = {})
      raise ArgumentError, 'trace_id is required for creating an observation' unless attributes[:trace_id]
      raise ArgumentError, 'type is required (SPAN, GENERATION, or EVENT)' unless attributes[:type]

      observation = Models::Observation.new(attributes)
      event = Models::IngestionEvent.new(
        type: 'observation-create',
        body: observation
      )
      enqueue_event(event)
      observation
    end

    # Updates an existing observation
    def update_observation(observation)
      raise ArgumentError, 'observation.id is required for updating an observation' unless observation.id

      event = Models::IngestionEvent.new(
        type: 'observation-update',
        body: observation
      )
      enqueue_event(event)
      observation
    end

    # Creates a new score
    def score(attributes = {})
      raise ArgumentError, 'trace_id is required for creating a score' unless attributes[:trace_id]

      score = Models::Score.new(attributes)
      event = Models::IngestionEvent.new(
        type: 'score-create',
        body: score
      )
      enqueue_event(event)
      score
    end

    # Flushes all pending events to the API
    def flush
      events_to_process = []

      # Atomically swap the events array to avoid race conditions
      @mutex.synchronize do
        events_to_process = @events.dup
        @events.clear
      end

      return if events_to_process.empty?

      # Convert objects to hashes for serialization
      event_hashes = events_to_process.map(&:to_h)

      log("Flushing #{event_hashes.size} events")

      # Send to job backend via adapter
      @job_adapter.enqueue(event_hashes)
    end

    # Gracefully shuts down the client, ensuring all events are flushed
    def shutdown
      log('Shutting down Langfuse client...')

      # Cancel the flush timer if it's running
      @flush_thread&.exit

      # Flush any remaining events
      flush

      log('Langfuse client shut down.')
    end

    private

    def enqueue_event(event)
      @events << event

      # Trigger immediate flush if batch size reached
      # Assuming @config.batch_size is an Integer
      flush if @events.size >= @config.batch_size
    end

    def schedule_periodic_flush
      log("Starting periodic flush thread (interval: #{@config.flush_interval}s)")

      @flush_thread = Thread.new do
        loop do
          # Assuming @config.flush_interval is Numeric
          sleep @config.flush_interval
          flush
        rescue StandardError => e
          log("Error in Langfuse flush thread: #{e.message}", :error)
          sleep 1 # Avoid tight loop on persistent errors
        end
      end
    end

    def log(message, level = :debug)
      # Assuming @config.debug is Boolean
      return unless @config.debug

      @config.logger.send(level, "[Langfuse] #{message}")
    end

    def validate_configuration!
      errors = []
      errors << 'public_key is required' if @config.public_key.nil? || @config.public_key.empty?
      errors << 'secret_key is required' if @config.secret_key.nil? || @config.secret_key.empty?

      errors << 'host must start with http:// or https://' unless @config.host.start_with?('http://', 'https://')

      return if errors.empty?

      raise ArgumentError, "Langfuse configuration errors:\n  #{errors.join("\n  ")}"
    end
  end
end
