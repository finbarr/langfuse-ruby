# frozen_string_literal: true
# typed: true

require 'securerandom'

module Langfuse
  module Models
    class Generation
      attr_accessor :id, :trace_id, :name, :start_time, :end_time,
                    :metadata, :input, :output, :level, :status_message,
                    :parent_observation_id, :version, :environment,
                    :completion_start_time, :model, :model_parameters,
                    :usage, :usage_details, :cost_details, :prompt_name,
                    :prompt_version, :type

      def initialize(attributes = {})
        attributes.each do |key, value|
          send("#{key}=", value) if respond_to?("#{key}=")
        end
        @id ||= SecureRandom.uuid
        @start_time ||= Time.now.utc
        @type ||= 'GENERATION'
      end

      def to_h
        {
          id: @id,
          traceId: @trace_id,
          type: @type,
          name: @name,
          startTime: @start_time&.iso8601(3),
          endTime: @end_time&.iso8601(3),
          metadata: @metadata,
          input: process_input(@input),
          output: process_output(@output),
          level: @level,
          statusMessage: @status_message,
          parentObservationId: @parent_observation_id,
          version: @version,
          environment: @environment,
          completionStartTime: @completion_start_time&.iso8601(3),
          model: @model,
          modelParameters: @model_parameters,
          usage: @usage.respond_to?(:to_h) ? @usage.to_h : @usage,
          usageDetails: @usage_details,
          costDetails: @cost_details,
          promptName: @prompt_name,
          promptVersion: @prompt_version
        }.compact
      end

      private

      # Process input to ensure proper formatting for tool definitions
      def process_input(input)
        return input unless input.is_a?(Hash)

        # Check if input contains tools or function definitions
        if input[:tools] || input[:functions]
          processed = input.dup

          # Ensure tools are properly formatted
          processed[:tools] = input[:tools].map { |tool| format_tool(tool) } if input[:tools]

          # Handle tool_choice if present
          processed[:tool_choice] = input[:tool_choice] if input[:tool_choice]

          processed
        else
          input
        end
      end

      # Process output to ensure proper formatting for tool calls
      def process_output(output)
        return output unless output.is_a?(Hash)

        # Check if output contains tool_calls
        if output[:tool_calls]
          processed = output.dup
          processed[:tool_calls] = output[:tool_calls].map { |call| format_tool_call(call) }
          processed
        else
          output
        end
      end

      # Format a tool definition
      def format_tool(tool)
        return tool unless tool.is_a?(Hash)
        
        # If tool already has the correct structure, return it as-is
        if tool[:type] && tool[:function]
          return tool
        end
        
        # Otherwise, format it
        {
          type: tool[:type] || 'function',
          function: tool[:function] || {
            name: tool[:name],
            description: tool[:description],
            parameters: tool[:parameters]
          }.compact
        }.compact
      end

      # Format a tool call
      def format_tool_call(call)
        return call unless call.is_a?(Hash)

        {
          id: call[:id],
          type: call[:type] || 'function',
          function: {
            name: call.dig(:function, :name),
            arguments: call.dig(:function, :arguments)
          }.compact
        }.compact
      end
    end
  end
end
