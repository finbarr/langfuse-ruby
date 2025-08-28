# frozen_string_literal: true
# typed: true

require 'securerandom'

module Langfuse
  module Models
    class Tool
      attr_accessor :id, :trace_id, :name, :start_time, :end_time,
                    :metadata, :input, :output, :level, :status_message,
                    :parent_observation_id, :version, :environment,
                    :tool_name, :tool_call_id, :arguments

      def initialize(attributes = {})
        attributes.each do |key, value|
          send("#{key}=", value) if respond_to?("#{key}=")
        end
        @id ||= SecureRandom.uuid
        @start_time ||= Time.now.utc
      end

      def to_h
        {
          id: @id,
          traceId: @trace_id,
          name: @name,
          startTime: @start_time&.iso8601(3),
          endTime: @end_time&.iso8601(3),
          metadata: @metadata,
          input: @input,
          output: @output,
          level: @level,
          statusMessage: @status_message,
          parentObservationId: @parent_observation_id,
          version: @version,
          environment: @environment,
          toolName: @tool_name,
          toolCallId: @tool_call_id,
          arguments: @arguments
        }.compact
      end
    end
  end
end
