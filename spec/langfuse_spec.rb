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
      expect(mock_client).to receive(:trace).with(name: 'test').and_return(mock_trace)
      
      result = described_class.trace(name: 'test')
      expect(result).to eq(mock_trace)
    end

    it 'delegates span to client' do
      mock_span = instance_double(Langfuse::Models::Span)
      expect(mock_client).to receive(:span).with(name: 'test').and_return(mock_span)
      
      result = described_class.span(name: 'test')
      expect(result).to eq(mock_span)
    end

    it 'delegates flush to client' do
      expect(mock_client).to receive(:flush)
      described_class.flush
    end
  end
end