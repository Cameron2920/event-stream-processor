# frozen_string_literal: true

class MetricAggregator
  def initialize(event)
    @event = event
  end

  def aggregate
    REDIS_POOL.with do |redis|
      increment_counters(redis)
      track_latency(redis)
      update_recent_events(redis)
    end
  end

  private

  # Keep track of event counts globally, by type and by hour
  def increment_counters(redis)
    redis.incr('metrics:events:total')
    redis.incr("metrics:events:by_type:#{@event.event_type}")
    hour_key = @event.processed_at.beginning_of_hour.to_i
    redis.incr("metrics:events:hourly:#{hour_key}")
    redis.expire("metrics:events:hourly:#{hour_key}", 25.hours.to_i)
  end

  # Keep track of the last 1000 latencies in ms
  def track_latency(redis)
    latency = (@event.processed_at - @event.occurred_at) * 1000
    redis.lpush('metrics:latencies', latency.round)
    redis.ltrim('metrics:latencies', 0, 999)
  end

  # Keep track of the last 100 events
  def update_recent_events(redis)
    event_summary = {
      id: @event.id,
      type: @event.event_type,
      timestamp: @event.occurred_at.iso8601
    }.to_json
    redis.zadd('metrics:recent_events', @event.occurred_at.to_i, event_summary)
    redis.zremrangebyrank('metrics:recent_events', 0, -101)
  end
end