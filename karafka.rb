# frozen_string_literal: true

class KarafkaApp < Karafka::App
  setup do |config|
    config.kafka = {
      'bootstrap.servers': ENV.fetch('KAFKA_BROKERS', 'localhost:29092'),
      'client.id': 'event-processor'
    }

    config.client_id = 'event-stream-processor'
    config.consumer_persistence = true
    config.concurrency = 5
    config.max_wait_time = 1_000
    config.shutdown_timeout = 60_000
    config.logger = Logger.new(STDOUT)
    config.logger.level = Logger::INFO
  end

  routes.draw do
    topic "events" do
      consumer EventsConsumer
    end

    topic "events.retry" do
      consumer EventsConsumer
    end
  end
end

Karafka.monitor.subscribe('error.occurred') do |event|
  Rails.logger.error "KARAFKA ERROR OCCURRED!"
  Rails.logger.error "Type: #{event[:type]}"
  Rails.logger.error "Error: #{event[:error].class} - #{event[:error].message}"
  Rails.logger.error "Backtrace:"
  Rails.logger.error event[:error].backtrace.first(10).join("\n")
end