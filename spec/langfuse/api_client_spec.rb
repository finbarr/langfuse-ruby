# frozen_string_literal: true

RSpec.describe Langfuse::ApiClient do
  let(:config) do
    instance_double(
      Langfuse::Configuration,
      public_key: 'test-public-key',
      secret_key: 'test-secret-key',
      host: 'https://test.langfuse.com',
      debug: false
    )
  end
  
  subject(:client) { described_class.new(config) }

  describe '#ingest' do
    let(:events) do
      [
        { 
          id: 'event-1',
          type: 'trace',
          body: { name: 'test-trace' }
        }
      ]
    end

    before do
      stub_request(:post, 'https://test.langfuse.com/api/public/ingestion')
        .to_return(status: 200, body: { success: true }.to_json)
    end

    it 'sends events to the API' do
      response = client.ingest(events)
      
      expect(response).to include('success' => true)
      expect(WebMock).to have_requested(:post, 'https://test.langfuse.com/api/public/ingestion')
        .with(body: { batch: events })
        .once
    end

    it 'includes authorization header' do
      expected_auth = Base64.strict_encode64('test-public-key:test-secret-key')
      
      client.ingest(events)
      
      expect(WebMock).to have_requested(:post, 'https://test.langfuse.com/api/public/ingestion')
        .with(headers: { 'Authorization' => "Basic #{expected_auth}" })
        .once
    end

    context 'when API returns an error' do
      before do
        stub_request(:post, 'https://test.langfuse.com/api/public/ingestion')
          .to_return(status: 400, body: { error: 'Invalid request' }.to_json)
      end

      it 'raises an error' do
        expect { client.ingest(events) }.to raise_error(RuntimeError, /API request failed/)
      end
    end

    context 'with debug mode enabled' do
      let(:config) do
        instance_double(
          Langfuse::Configuration,
          public_key: 'test-public-key',
          secret_key: 'test-secret-key',
          host: 'https://test.langfuse.com',
          debug: true
        )
      end

      it 'logs debug information' do
        expect(client).to receive(:log).at_least(:once)
        client.ingest(events)
      end
    end
  end
end