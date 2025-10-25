# frozen_string_literal: true

class EventsConsumer < ApplicationConsumer
  def consume
    Rails.logger.info("Consuming events: #{messages.size}")
    events = []

    messages.each do |message|
      begin
        events << process_message(message)
      rescue StandardError => error
        Rails.logger.error("Error processing message: #{error}")
        # Retry failures on separate topic to optimize throughput
        send_to_retry_topic(message, error)
      end
    end
    Rails.logger.info("Consumed events: #{events.size}")
  end

  private

  def process_message(message)
    Rails.logger.info("Processing event: #{message.payload}")
    event_data = message.payload

    # Idempotency check
    return if already_processed?(event_data['event_id'])
    event = nil

    ActiveRecord::Base.transaction do
      event = create_event(event_data)
      trigger_downstream_processing(event)
    end
    update_metrics(event)
    event
  end

  def send_to_retry_topic(message, error)
    retry_count = message.headers['retry_count']&.to_i || 0

    Karafka.producer.produce_async(
      topic: "#{message.topic}.retry",
      payload: message.payload,
      key: message.key,
      headers: {
        'original_topic' => message.topic,
        'original_offset' => message.offset.to_s,
        'original_partition' => message.partition.to_s,
        'error' => error.message,
        'error_class' => error.class.to_s,
        'retry_count' => (retry_count + 1).to_s,
        'failed_at' => Time.now.iso8601
      }
    )
  end

  def already_processed?(event_id)
    Event.exists?(event_id: event_id)
  end

  def create_event(event_data)
    Event.create!(
      event_id: event_data['event_id'],
      event_type: event_data['event_type'],
      payload: event_data['payload'],
      source: event_data['source'],
      occurred_at: Time.parse(event_data['timestamp']),
      processed_at: Time.current
    )
  end

  def update_metrics(event)
    MetricAggregator.new(event).aggregate
  end

  def trigger_downstream_processing(event)
    # TODO: Trigger additional processing based on event type
  end
end