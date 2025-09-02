# frozen_string_literal: true
# typed: true

require 'securerandom'

module Langfuse
  module Models
    # Generic observation model that can represent SPAN, GENERATION, or EVENT types
    class Observation
      attr_accessor :id, :trace_id, :type, :name, :start_time, :end_time,
                    :metadata, :input, :output, :level, :status_message,
                    :parent_observation_id, :version, :environment,
                    :completion_start_time, :model, :model_parameters,
                    :usage, :usage_details, :cost_details,
                    :prompt_name, :prompt_version, :prompt_id

      def initialize(attributes = {})
        attributes.each do |key, value|
          send("#{key}=", value) if respond_to?("#{key}=")
        end
        @id ||= SecureRandom.uuid
        @start_time ||= Time.now.utc

        # Default type based on provided attributes
        @type ||= determine_type(attributes)
      end

      def to_h
        base_hash = {
          id: @id,
          traceId: @trace_id,
          type: @type,
          name: @name,
          startTime: @start_time&.iso8601(3),
          metadata: @metadata,
          input: @input,
          output: @output,
          level: @level,
          statusMessage: @status_message,
          parentObservationId: @parent_observation_id,
          version: @version,
          environment: @environment
        }

        # Add type-specific fields
        case @type
        when 'GENERATION'
          base_hash.merge!({
                             endTime: @end_time&.iso8601(3),
                             completionStartTime: @completion_start_time&.iso8601(3),
                             model: @model,
                             modelParameters: @model_parameters,
                             usage: @usage.respond_to?(:to_h) ? @usage.to_h : @usage,
                             usageDetails: @usage_details,
                             costDetails: @cost_details,
                             promptName: @prompt_name,
                             promptVersion: @prompt_version,
                             promptId: @prompt_id
                           })
        when 'SPAN'
          base_hash.merge!({
                             endTime: @end_time&.iso8601(3)
                           })
        when 'EVENT'
          # Events don't have end_time
        end

        base_hash.compact
      end

      private

      def determine_type(attributes)
        # Determine type based on attributes
        if attributes[:model] || attributes[:completion_start_time] ||
           attributes[:prompt_name] || attributes[:usage]
          'GENERATION'
        elsif attributes[:end_time]
          'SPAN'
        else
          'EVENT'
        end
      end
    end
  end
end
