# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'base64'

module Langfuse
  class ApiClient
    attr_reader :config

    def initialize(config)
      @config = config
    end

    def ingest(events)
      uri = URI.parse("#{@config.host}/api/public/ingestion")

      # Build the request
      request = Net::HTTP::Post.new(uri.path)
      request.content_type = 'application/json'

      # Set authorization header using base64 encoded credentials
      auth = Base64.strict_encode64("#{@config.public_key}:#{@config.secret_key}")
      # Log the auth header for debugging (masked for security)
      if @config.debug
        masked_auth = "#{auth[0..5]}...#{auth[-4..]}"
        masked_secret = @config.secret_key ? "#{@config.secret_key[0..7]}..." : 'nil'
        log("Using auth header: Basic #{masked_auth} (public_key: #{@config.public_key}, secret_key: #{masked_secret})")
      end
      request['Authorization'] = "Basic #{auth}"

      # Set the payload
      request.body = {
        batch: events
      }.to_json

      # Send the request
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.read_timeout = 10 # 10 seconds

      if @config.debug
        log("Sending #{events.size} events to Langfuse API at #{@config.host}")
        log("Events: #{events.inspect}")
        log("Request url: #{uri}")
      end

      log('---') # Moved log statement before response handling to avoid affecting return value

      response = http.request(request)

      result = nil

      if response.code.to_i == 207 # Partial success
        log('Received 207 partial success response') if @config.debug
        result = JSON.parse(response.body)
      elsif response.code.to_i >= 200 && response.code.to_i < 300
        log("Received successful response: #{response.code}") if @config.debug
        result = JSON.parse(response.body)
      else
        error_msg = "API error: #{response.code} #{response.message}"
        if @config.debug
          log("Response body: #{response.body}", :error)
          log("Request URL: #{uri}", :error)
        end
        log(error_msg, :error)
        raise error_msg
      end

      result
    rescue StandardError => e
      log("Error during API request: #{e.message}", :error)
      raise
    end

    private

    def log(message, level = :debug)
      return unless @config.debug

      @config.logger.send(level, "[Langfuse] #{message}")
    end
  end
end
