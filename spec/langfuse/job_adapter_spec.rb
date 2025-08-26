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
      it 'auto-detects synchronous when no job libraries are available' do
        adapter = described_class.new
        expect(adapter.backend).to eq(:synchronous)
      end

      context 'with ActiveJob defined' do
        before do
          stub_const('ActiveJob', Class.new)
        end

        it 'auto-detects active_job' do
          adapter = described_class.new
          expect(adapter.backend).to eq(:active_job)
        end
      end

      context 'with Sidekiq defined' do
        before do
          stub_const('Sidekiq', Class.new)
          hide_const('ActiveJob') if defined?(ActiveJob)
        end

        it 'auto-detects sidekiq' do
          adapter = described_class.new
          expect(adapter.backend).to eq(:sidekiq)
        end
      end
    end
  end

  describe '#enqueue' do
    let(:adapter) { described_class.new(backend) }
    let(:api_client) { instance_double(Langfuse::ApiClient) }

    before do
      allow(Langfuse::ApiClient).to receive(:new).and_return(api_client)
      allow(api_client).to receive(:ingest).and_return({ 'success' => true })
    end

    context 'with synchronous backend' do
      let(:backend) { :synchronous }

      it 'processes events synchronously' do
        adapter.enqueue(event_hashes)
        expect(api_client).to have_received(:ingest).with(event_hashes)
      end
    end

    context 'with sidekiq backend' do
      let(:backend) { :sidekiq }
      let(:batch_worker) { class_double('Langfuse::BatchWorker') }

      before do
        stub_const('Langfuse::BatchWorker', batch_worker)
        allow(batch_worker).to receive(:perform_async)
      end

      it 'enqueues to Sidekiq' do
        adapter.enqueue(event_hashes)
        expect(batch_worker).to have_received(:perform_async).with(event_hashes)
      end
    end

    context 'with active_job backend' do
      let(:backend) { :active_job }

      before do
        # Don't actually load the job file in tests
        allow(adapter).to receive(:require).with('langfuse/jobs/batch_ingestion_job')

        # Create a mock job class
        job_class = class_double('Langfuse::Jobs::BatchIngestionJob')
        stub_const('Langfuse::Jobs::BatchIngestionJob', job_class)
        allow(job_class).to receive(:perform_later)
      end

      it 'enqueues to ActiveJob' do
        adapter.enqueue(event_hashes)
        expect(Langfuse::Jobs::BatchIngestionJob).to have_received(:perform_later).with(event_hashes)
      end
    end

    context 'with unknown backend' do
      let(:backend) { :unknown }

      it 'raises an error' do
        expect { adapter.enqueue(event_hashes) }.to raise_error(ArgumentError, /Unknown job backend/)
      end
    end
  end
end
