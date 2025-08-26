# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Langfuse::Jobs::BatchIngestionJob' do
  let(:event_hashes) do
    [
      { id: 'event-1', type: 'trace', body: { name: 'test' } }
    ]
  end
  
  let(:api_client) { instance_double(Langfuse::ApiClient) }
  let(:config) { instance_double(Langfuse::Configuration) }

  before do
    allow(Langfuse).to receive(:configuration).and_return(config)
    allow(Langfuse::ApiClient).to receive(:new).with(config).and_return(api_client)
  end

  context 'when ActiveJob is available' do
    before do
      # Mock ActiveJob
      active_job_base = Class.new do
        def self.queue_as(_name); end
        def self.retry_on(*_args); end
        def self.discard_on(*_args); end
      end
      
      stub_const('ActiveJob::Base', active_job_base)
      
      # Require the job after stubbing ActiveJob
      require 'langfuse/jobs/batch_ingestion_job'
    end
    
    let(:job) { Langfuse::Jobs::BatchIngestionJob.new }

    describe '#perform' do
      context 'with successful ingestion' do
        before do
          allow(api_client).to receive(:ingest).and_return({ 'success' => true })
        end

        it 'ingests events successfully' do
          job.perform(event_hashes)
          expect(api_client).to have_received(:ingest).with(event_hashes)
        end
      end

      context 'with partial failures' do
        let(:response) do
          {
            'success' => false,
            'errors' => [
              { 'id' => 'event-1', 'message' => 'Invalid event', 'status' => 400 }
            ]
          }
        end

        before do
          allow(api_client).to receive(:ingest).and_return(response)
          stub_const('Rails', double(logger: double(error: nil), cache: nil))
        end

        it 'handles errors' do
          expect(Rails.logger).to receive(:error).with(/Invalid event/)
          job.perform(event_hashes)
        end
      end

      context 'with network errors' do
        before do
          allow(api_client).to receive(:ingest).and_raise(Net::ReadTimeout)
          stub_const('Rails', double(logger: double(error: nil)))
        end

        it 're-raises network errors for retry' do
          expect { job.perform(event_hashes) }.to raise_error(Net::ReadTimeout)
        end
      end

      context 'with client errors' do
        before do
          allow(api_client).to receive(:ingest).and_raise(RuntimeError, '400 Bad Request')
          stub_const('Rails', double(logger: double(error: nil)))
        end

        it 'converts to ArgumentError to prevent retry' do
          expect { job.perform(event_hashes) }.to raise_error(ArgumentError, /400 Bad Request/)
        end
      end
    end
  end

  context 'when ActiveJob is not available' do
    # Skip this test as it's difficult to test due to conditional class definition
    # The functionality is covered by the JobAdapter tests
    it 'skipped - covered by JobAdapter synchronous backend test' do
      skip 'This is tested via JobAdapter synchronous backend'
    end
  end
end