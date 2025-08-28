# frozen_string_literal: true

require 'spec_helper'
require 'langfuse/models/tool'

RSpec.describe Langfuse::Models::Tool do
  describe '#initialize' do
    it 'creates a Tool with provided attributes' do
      attributes = {
        trace_id: 'trace-123',
        name: 'calculator',
        tool_name: 'add_numbers',
        tool_call_id: 'call-456',
        arguments: { a: 1, b: 2 },
        input: { numbers: [1, 2] },
        metadata: { version: '1.0' }
      }

      tool = described_class.new(attributes)

      expect(tool.trace_id).to eq('trace-123')
      expect(tool.name).to eq('calculator')
      expect(tool.tool_name).to eq('add_numbers')
      expect(tool.tool_call_id).to eq('call-456')
      expect(tool.arguments).to eq({ a: 1, b: 2 })
      expect(tool.input).to eq({ numbers: [1, 2] })
      expect(tool.metadata).to eq({ version: '1.0' })
    end

    it 'generates an ID if not provided' do
      tool = described_class.new

      expect(tool.id).not_to be_nil
      expect(tool.id).to match(/^[a-f0-9-]{36}$/)
    end

    it 'sets start_time to current time if not provided' do
      freeze_time = Time.now.utc
      allow(Time).to receive(:now).and_return(freeze_time)

      tool = described_class.new

      expect(tool.start_time).to eq(freeze_time)
    end
  end

  describe '#to_h' do
    it 'returns a hash representation with camelCase keys' do
      attributes = {
        id: 'tool-123',
        trace_id: 'trace-456',
        name: 'weather_tool',
        tool_name: 'get_weather',
        tool_call_id: 'call-789',
        arguments: { location: 'San Francisco' },
        start_time: Time.parse('2024-01-01 10:00:00 UTC'),
        end_time: Time.parse('2024-01-01 10:00:05 UTC'),
        output: { temperature: 72, conditions: 'sunny' },
        metadata: { api_version: '2.0' },
        level: 'INFO',
        status_message: 'Success',
        parent_observation_id: 'parent-123',
        version: 'v1',
        environment: 'production'
      }

      tool = described_class.new(attributes)
      hash = tool.to_h

      expect(hash[:id]).to eq('tool-123')
      expect(hash[:traceId]).to eq('trace-456')
      expect(hash[:name]).to eq('weather_tool')
      expect(hash[:toolName]).to eq('get_weather')
      expect(hash[:toolCallId]).to eq('call-789')
      expect(hash[:arguments]).to eq({ location: 'San Francisco' })
      expect(hash[:startTime]).to eq('2024-01-01T10:00:00.000Z')
      expect(hash[:endTime]).to eq('2024-01-01T10:00:05.000Z')
      expect(hash[:output]).to eq({ temperature: 72, conditions: 'sunny' })
      expect(hash[:metadata]).to eq({ api_version: '2.0' })
      expect(hash[:level]).to eq('INFO')
      expect(hash[:statusMessage]).to eq('Success')
      expect(hash[:parentObservationId]).to eq('parent-123')
      expect(hash[:version]).to eq('v1')
      expect(hash[:environment]).to eq('production')
    end

    it 'excludes nil values from the hash' do
      tool = described_class.new(id: 'tool-123', trace_id: 'trace-456')
      hash = tool.to_h

      expect(hash.keys).to contain_exactly(:id, :traceId, :startTime)
      expect(hash).not_to have_key(:output)
      expect(hash).not_to have_key(:endTime)
      expect(hash).not_to have_key(:toolName)
    end
  end

  describe 'usage pattern for tool calls' do
    it 'supports creating and updating a tool observation' do
      # 1. Create tool observation when starting the tool call
      tool = described_class.new(
        trace_id: 'trace-123',
        name: 'Search API',
        tool_name: 'web_search',
        tool_call_id: 'call-unique-123',
        arguments: { query: 'Ruby programming', max_results: 10 },
        input: { user_query: 'Tell me about Ruby programming' }
      )

      expect(tool.output).to be_nil
      expect(tool.end_time).to be_nil

      # 2. Update tool observation after execution
      tool.output = { results: ['Result 1', 'Result 2'], count: 2 }
      tool.end_time = Time.now.utc
      tool.status_message = 'Search completed successfully'

      hash = tool.to_h
      expect(hash[:output]).to eq({ results: ['Result 1', 'Result 2'], count: 2 })
      expect(hash[:endTime]).not_to be_nil
      expect(hash[:statusMessage]).to eq('Search completed successfully')
    end
  end
end
