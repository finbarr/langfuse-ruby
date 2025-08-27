# frozen_string_literal: true

require 'spec_helper'
require 'langfuse/job_adapter'

RSpec.describe Langfuse::JobAdapter do
  let(:event_hashes) do
    [
      { id: 'event-1', type: 'trace', body: { name: 'test' } }
    ]
  end

  describe '#initialize' do
    context 'when backend is explicitly set' do
      it 'uses the specified backend' do
        adapter = described_class.new(:synchronous)
        expect(adapter.backend).to eq(:synchronous)
      end
    end

    context 'when backend is not set' do
      it 'defaults to synchronous' do
        adapter = described_class.new
        expect(adapter.backend).to eq(:synchronous)
      end
    end
  end

  describe '#enqueue' do
    let(:api_client) { instance_double(Langfuse::ApiClient) }
    let(:config) { instance_double(Langfuse::Configuration, queue_name: 'langfuse') }

    before do
      allow(Langfuse).to receive(:configuration).and_return(config)
      allow(Langfuse::ApiClient).to receive(:new).with(config).and_return(api_client)
    end

    context 'with synchronous backend' do
      let(:adapter) { described_class.new(:synchronous) }

      it 'processes events synchronously' do
        allow(api_client).to receive(:ingest).with(event_hashes).and_return({ 'success' => true })
        adapter.enqueue(event_hashes)
        expect(api_client).to have_received(:ingest).with(event_hashes)
      end
    end

    context 'with sidekiq backend' do
      let(:adapter) { described_class.new(:sidekiq) }

      context 'when Sidekiq support is loaded' do
        before do
          batch_worker = Class.new do
            def self.perform_async(_events)
              true
            end
          end
          stub_const('Langfuse::BatchWorker', batch_worker)
        end

        it 'enqueues to Sidekiq' do
          allow(Langfuse::BatchWorker).to receive(:perform_async).with(event_hashes)
          adapter.enqueue(event_hashes)
          expect(Langfuse::BatchWorker).to have_received(:perform_async).with(event_hashes)
        end
      end

      context 'when Sidekiq support is not loaded' do
        before do
          hide_const('Langfuse::BatchWorker')
        end

        it 'raises an error' do
          expect { adapter.enqueue(event_hashes) }.to raise_error(/Sidekiq support not loaded/)
        end
      end
    end

    context 'with active_job backend' do
      let(:adapter) { described_class.new(:active_job) }

      context 'when ActiveJob support is loaded' do
        before do
          job_class = Class.new do
            def self.perform_later(_events)
              true
            end
          end
          stub_const('Langfuse::Jobs::BatchIngestionJob', job_class)
        end

        it 'enqueues to ActiveJob' do
          allow(Langfuse::Jobs::BatchIngestionJob).to receive(:perform_later).with(event_hashes)
          adapter.enqueue(event_hashes)
          expect(Langfuse::Jobs::BatchIngestionJob).to have_received(:perform_later).with(event_hashes)
        end
      end

      context 'when ActiveJob support is not loaded' do
        before do
          hide_const('Langfuse::Jobs::BatchIngestionJob') if defined?(Langfuse::Jobs::BatchIngestionJob)
        end

        it 'raises an error' do
          expect { adapter.enqueue(event_hashes) }.to raise_error(/ActiveJob support not loaded/)
        end
      end
    end

    context 'with unknown backend' do
      let(:adapter) { described_class.new(:unknown_backend) }

      it 'raises an error' do
        expect { adapter.enqueue(event_hashes) }.to raise_error(ArgumentError, /Unknown job backend/)
      end
    end
  end
end