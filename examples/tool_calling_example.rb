# frozen_string_literal: true

require 'langfuse'
require 'json'

# Configure Langfuse
Langfuse.configure do |config|
  config.public_key = ENV['LANGFUSE_PUBLIC_KEY']
  config.secret_key = ENV['LANGFUSE_SECRET_KEY']
  config.host = ENV.fetch('LANGFUSE_HOST', 'https://us.cloud.langfuse.com')
  config.debug = true
end

# Example: Tracking an LLM interaction with tool/function calling
class ToolCallingExample
  def run
    # Create a trace for the entire conversation
    trace = Langfuse.trace(
      name: "weather-assistant-conversation",
      user_id: "user-123",
      metadata: {
        feature: "weather-inquiry",
        version: "1.0.0"
      },
      tags: ["production", "tools", "weather"]
    )

    # Track the initial LLM call with tool definitions
    generation = Langfuse.generation(
      name: "openai-chat-with-tools",
      trace_id: trace.id,
      model: "gpt-4-turbo",
      model_parameters: {
        temperature: 0.3,
        max_tokens: 500,
        tool_choice: "auto"
      },
      input: {
        messages: [
          {
            role: "user",
            content: "What's the weather like in Tokyo and New York?"
          }
        ],
        tools: [
          {
            type: "function",
            function: {
              name: "get_current_weather",
              description: "Get the current weather in a given location",
              parameters: {
                type: "object",
                properties: {
                  location: {
                    type: "string",
                    description: "The city and state/country"
                  },
                  unit: {
                    type: "string",
                    enum: ["celsius", "fahrenheit"],
                    default: "celsius"
                  }
                },
                required: ["location"]
              }
            }
          }
        ],
        tool_choice: "auto"
      },
      output: {
        role: "assistant",
        content: nil,
        tool_calls: [
          {
            id: "call_tokyo_weather",
            type: "function",
            function: {
              name: "get_current_weather",
              arguments: JSON.generate({ location: "Tokyo, Japan", unit: "celsius" })
            }
          },
          {
            id: "call_ny_weather",
            type: "function",
            function: {
              name: "get_current_weather",
              arguments: JSON.generate({ location: "New York, USA", unit: "fahrenheit" })
            }
          }
        ]
      },
      usage: {
        input: 120,
        output: 45,
        total: 165,
        unit: "TOKENS"
      },
      usage_details: {
        prompt_tokens: 120,
        completion_tokens: 45,
        total_tokens: 165
      },
      cost_details: {
        input: 0.0012,
        output: 0.0009,
        total: 0.0021
      },
      metadata: {
        tool_use: true,
        parallel_calls: 2
      }
    )

    # Track the tool execution as spans
    tokyo_weather_span = Langfuse.span(
      name: "get_current_weather",
      trace_id: trace.id,
      parent_observation_id: generation.id,
      input: {
        location: "Tokyo, Japan",
        unit: "celsius"
      },
      output: {
        temperature: 22,
        condition: "sunny",
        humidity: 45
      },
      metadata: {
        tool_call_id: "call_tokyo_weather",
        api: "weather_api"
      }
    )

    ny_weather_span = Langfuse.span(
      name: "get_current_weather",
      trace_id: trace.id,
      parent_observation_id: generation.id,
      input: {
        location: "New York, USA",
        unit: "fahrenheit"
      },
      output: {
        temperature: 68,
        condition: "cloudy",
        humidity: 60
      },
      metadata: {
        tool_call_id: "call_ny_weather",
        api: "weather_api"
      }
    )

    # Track the final LLM response with tool results
    final_generation = Langfuse.generation(
      name: "openai-chat-tool-response",
      trace_id: trace.id,
      parent_observation_id: generation.id,
      model: "gpt-4-turbo",
      input: {
        messages: [
          {
            role: "user",
            content: "What's the weather like in Tokyo and New York?"
          },
          {
            role: "assistant",
            content: nil,
            tool_calls: [
              {
                id: "call_tokyo_weather",
                type: "function",
                function: {
                  name: "get_current_weather",
                  arguments: JSON.generate({ location: "Tokyo, Japan", unit: "celsius" })
                }
              },
              {
                id: "call_ny_weather",
                type: "function",
                function: {
                  name: "get_current_weather",
                  arguments: JSON.generate({ location: "New York, USA", unit: "fahrenheit" })
                }
              }
            ]
          },
          {
            role: "tool",
            tool_call_id: "call_tokyo_weather",
            content: JSON.generate({ temperature: 22, condition: "sunny", humidity: 45 })
          },
          {
            role: "tool",
            tool_call_id: "call_ny_weather",
            content: JSON.generate({ temperature: 68, condition: "cloudy", humidity: 60 })
          }
        ]
      },
      output: {
        role: "assistant",
        content: "Here's the current weather:\n\n**Tokyo, Japan**: 22°C, sunny with 45% humidity\n**New York, USA**: 68°F, cloudy with 60% humidity\n\nTokyo has pleasant sunny weather while New York is experiencing cloudy conditions."
      },
      usage: {
        input: 180,
        output: 42,
        total: 222,
        unit: "TOKENS"
      }
    )

    # Update the trace with final output
    trace.output = {
      weather_data: {
        tokyo: { temperature: 22, unit: "celsius", condition: "sunny" },
        new_york: { temperature: 68, unit: "fahrenheit", condition: "cloudy" }
      },
      response: final_generation.output[:content]
    }

    # Add a score to evaluate the interaction
    Langfuse.score(
      trace_id: trace.id,
      observation_id: final_generation.id,
      name: "quality",
      value: 0.95,
      comment: "Accurate weather information with proper tool usage"
    )

    # Ensure all events are sent
    Langfuse.flush

    puts "Successfully tracked tool calling interaction!"
    puts "Trace ID: #{trace.id}"
  end
end

# Run the example
if __FILE__ == $0
  ToolCallingExample.new.run
end