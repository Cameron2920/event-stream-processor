# frozen_string_literal: true

module Api
  class EventsController < ApplicationController
    skip_before_action :verify_authenticity_token
    def create
      event_data = build_event_data
      # Publish to Kafka asynchronously
      publish_to_kafka(event_data)
      render json: {
        status: 'accepted',
        event_id: event_data[:event_id]
      }, status: :accepted
    rescue StandardError => error
      Rails.logger.error("Event ingestion failed: #{error.message}")
      render json: { error: 'Event processing failed' }, status: :unprocessable_entity
    end

    private

    def build_event_data
      {
        event_id: SecureRandom.uuid,
        event_type: params[:event_type],
        payload: params[:payload],
        timestamp: Time.current.iso8601,
        source: 'api'
      }
    end

    def publish_to_kafka(event_data)
      # Use Karafka.producer.produce_async is quicker, but can lead to message loss if kafka is down
      # Opt for Karafka.producer.produce_sync in scenarios where data loss is not acceptable
      Karafka.producer.produce_async(
        topic: 'events',
        payload: event_data.to_json,
        key: event_data[:event_id]
      )
    end

    def event_params
      params.permit(:event_type, payload: {})
    end
  end
end