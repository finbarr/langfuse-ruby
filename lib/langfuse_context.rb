# frozen_string_literal: true

class LangfuseContext
  # Gets the current context hash for the thread
  def self.current
    context = Thread.current[:langfuse_context]
    # Initialize if nil
    context ||= {}
    Thread.current[:langfuse_context] = context
    context
  end

  # Gets the current trace ID from the context
  def self.current_trace_id
    current[:trace_id]
  end

  # Gets the current span ID from the context
  def self.current_span_id
    current[:span_id]
  end

  # Executes a block with a specific trace context
  def self.with_trace(trace, &_block)
    old_context = current.dup
    begin
      # Assuming trace.id returns a String
      trace_id = trace.id
      Thread.current[:langfuse_context] = { trace_id: trace_id } if trace_id
      yield
    ensure
      Thread.current[:langfuse_context] = old_context
    end
  end

  # Executes a block with a specific span context (merging with existing context)
  def self.with_span(span, &_block)
    old_context = current.dup
    begin
      # Assuming span.id returns a String
      span_id = span.id
      # Merge span_id into the current context
      new_context = current.merge({ span_id: span_id })
      Thread.current[:langfuse_context] = new_context if span_id
      yield
    ensure
      Thread.current[:langfuse_context] = old_context
    end
  end
end
