# frozen_string_literal: true

RSpec.describe Langfuse do
  it 'has a version number' do
    expect(Langfuse::VERSION).not_to be_nil
  end

  describe '.configure' do
    it 'yields configuration object' do
      expect { |b| described_class.configure(&b) }.to yield_with_args(Langfuse::Configuration)
    end

    it 'sets configuration values' do
      described_class.configure do |config|
        config.public_key = 'pk-test'
        config.secret_key = 'sk-test'
        config.host = 'https://custom.langfuse.com'
      end

      expect(described_class.configuration.public_key).to eq('pk-test')
      expect(described_class.configuration.secret_key).to eq('sk-test')
      expect(described_class.configuration.host).to eq('https://custom.langfuse.com')
    end
  end

  describe 'delegated methods' do
    let(:mock_client) { instance_double(Langfuse::Client) }

    before do
      allow(Langfuse::Client).to receive(:instance).and_return(mock_client)
    end

    it 'delegates trace to client' do
      mock_trace = instance_double(Langfuse::Models::Trace)
      allow(mock_client).to receive(:trace).with(hash_including(name: 'test')).and_return(mock_trace)

      result = described_class.trace(name: 'test')

      expect(result).to eq(mock_trace)
      expect(mock_client).to have_received(:trace).with(hash_including(name: 'test'))
    end

    it 'delegates span to client' do
      mock_span = instance_double(Langfuse::Models::Span)
      allow(mock_client).to receive(:span).with(hash_including(name: 'test')).and_return(mock_span)

      result = described_class.span(name: 'test')

      expect(result).to eq(mock_span)
      expect(mock_client).to have_received(:span).with(hash_including(name: 'test'))
    end

    it 'delegates flush to client' do
      allow(mock_client).to receive(:flush)
      described_class.flush

      expect(mock_client).to have_received(:flush)
    end

    it 'delegates tool to client' do
      mock_tool = instance_double(Langfuse::Models::Tool)
      allow(mock_client).to receive(:tool).with(hash_including(name: 'test_tool')).and_return(mock_tool)

      result = described_class.tool(name: 'test_tool')

      expect(result).to eq(mock_tool)
      expect(mock_client).to have_received(:tool).with(hash_including(name: 'test_tool'))
    end

    it 'delegates update_tool to client' do
      mock_tool = instance_double(Langfuse::Models::Tool)
      allow(mock_client).to receive(:update_tool).with(mock_tool).and_return(mock_tool)

      result = described_class.update_tool(mock_tool)

      expect(result).to eq(mock_tool)
      expect(mock_client).to have_received(:update_tool).with(mock_tool)
    end
  end
end
