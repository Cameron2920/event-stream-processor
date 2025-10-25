# app/services/metrics_service.rb
class MetricReport
  def generate
    REDIS_POOL.with do |redis|
      {
        overview: fetch_overview(redis),
        by_type: fetch_by_type(redis),
        hourly: fetch_hourly_data(redis),
        latency: fetch_latency_stats(redis),
        recent_events: fetch_recent_events(redis)
      }
    end
  end

  private

  def fetch_overview(redis)
    {
      total_events: redis.get('metrics:events:total').to_i,
      avg_latency: calculate_avg_latency(redis),
      p95_latency: calculate_percentile_latency(redis, 95),
      p99_latency: calculate_percentile_latency(redis, 99)
    }
  end

  def fetch_by_type(redis)
    # Get all event type keys
    keys = redis.keys('metrics:events:by_type:*')

    keys.map do |key|
      event_type = key.split(':').last
      count = redis.get(key).to_i
      {
        type: event_type,
        count: count
      }
    end.sort_by { |h| -h[:count] }
  end

  def fetch_hourly_data(redis)
    # Get last 24 hours
    hours = []
    24.times do |i|
      hour_time = i.hours.ago.beginning_of_hour
      hour_key = hour_time.to_i
      count = redis.get("metrics:events:hourly:#{hour_key}").to_i

      hours << {
        hour: hour_time.strftime('%H:%M'),
        timestamp: hour_time.to_i,
        count: count
      }
    end

    hours.reverse
  end

  def fetch_latency_stats(redis)
    latencies = redis.lrange('metrics:latencies', 0, -1).map(&:to_f)

    return default_latency_stats if latencies.empty?

    {
      avg: (latencies.sum / latencies.size).round(2),
      min: latencies.min.round(2),
      max: latencies.max.round(2),
      p50: percentile(latencies, 50),
      p95: percentile(latencies, 95),
      p99: percentile(latencies, 99)
    }
  end

  def fetch_recent_events(redis)
    events = redis.zrevrange('metrics:recent_events', 0, 99, with_scores: true)

    events.map do |event_json, score|
      event_data = JSON.parse(event_json)
      event_data['occurred_at'] = Time.at(score).strftime('%Y-%m-%d %H:%M:%S')
      event_data
    end
  end

  def calculate_avg_latency(redis)
    latencies = redis.lrange('metrics:latencies', 0, -1).map(&:to_f)
    return 0 if latencies.empty?

    (latencies.sum / latencies.size).round(2)
  end

  def calculate_percentile_latency(redis, percentile)
    latencies = redis.lrange('metrics:latencies', 0, -1).map(&:to_f)
    return 0 if latencies.empty?

    self.percentile(latencies, percentile)
  end

  def percentile(array, percentile)
    return 0 if array.empty?

    sorted = array.sort
    index = (percentile / 100.0 * sorted.length).ceil - 1
    sorted[index].round(2)
  end

  def default_latency_stats
    {
      avg: 0,
      min: 0,
      max: 0,
      p50: 0,
      p95: 0,
      p99: 0
    }
  end
end