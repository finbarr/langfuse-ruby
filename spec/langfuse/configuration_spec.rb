# frozen_string_literal: true

RSpec.describe Langfuse::Configuration do
  subject(:config) { described_class.new }

  describe '#initialize' do
    context 'with default values' do
      it 'sets default host' do
        expect(config.host).to eq('https://us.cloud.langfuse.com')
      end

      it 'sets default batch_size' do
        expect(config.batch_size).to eq(10)
      end

      it 'sets default flush_interval' do
        expect(config.flush_interval).to eq(60)
      end

      it 'sets default debug to false' do
        expect(config.debug).to be(false)
      end

      it 'sets default disable_at_exit_hook to false' do
        expect(config.disable_at_exit_hook).to be(false)
      end

      it 'sets default shutdown_timeout' do
        expect(config.shutdown_timeout).to eq(5)
      end
    end

    context 'with environment variables' do
      before do
        ENV['LANGFUSE_PUBLIC_KEY'] = 'env-public-key'
        ENV['LANGFUSE_SECRET_KEY'] = 'env-secret-key'
        ENV['LANGFUSE_HOST'] = 'https://env.langfuse.com'
        ENV['LANGFUSE_BATCH_SIZE'] = '20'
        ENV['LANGFUSE_FLUSH_INTERVAL'] = '30'
        ENV['LANGFUSE_DEBUG'] = 'true'
        ENV['LANGFUSE_SHUTDOWN_TIMEOUT'] = '10'
      end

      after do
        ENV.delete('LANGFUSE_PUBLIC_KEY')
        ENV.delete('LANGFUSE_SECRET_KEY')
        ENV.delete('LANGFUSE_HOST')
        ENV.delete('LANGFUSE_BATCH_SIZE')
        ENV.delete('LANGFUSE_FLUSH_INTERVAL')
        ENV.delete('LANGFUSE_DEBUG')
        ENV.delete('LANGFUSE_SHUTDOWN_TIMEOUT')
      end

      it 'reads values from environment variables' do
        config = described_class.new
        
        expect(config.public_key).to eq('env-public-key')
        expect(config.secret_key).to eq('env-secret-key')
        expect(config.host).to eq('https://env.langfuse.com')
        expect(config.batch_size).to eq(20)
        expect(config.flush_interval).to eq(30)
        expect(config.debug).to be(true)
        expect(config.shutdown_timeout).to eq(10)
      end
    end
  end

  describe 'attribute accessors' do
    it 'allows setting and getting public_key' do
      config.public_key = 'new-public-key'
      expect(config.public_key).to eq('new-public-key')
    end

    it 'allows setting and getting secret_key' do
      config.secret_key = 'new-secret-key'
      expect(config.secret_key).to eq('new-secret-key')
    end

    it 'allows setting and getting host' do
      config.host = 'https://new.langfuse.com'
      expect(config.host).to eq('https://new.langfuse.com')
    end
  end
end