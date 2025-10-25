namespace :example_data do
  task :generate_metrics, [] => :environment do |t, args|
    REDIS_POOL.with do |redis|
      redis.flushall
    end

    event_types = ["user.sign_up", "user.sign_up", "user.sign_up", "user.login", "user.login", "post.created"]
    iterations = (0..5000).to_a
    minutes = (0..60).to_a
    ms = (100..300).to_a

    (0..24).each do |hour|
      (0..iterations.sample).each do |_|
        occurred_at = (DateTime.now - hour.hours).beginning_of_hour
        occurred_at = occurred_at + minutes.sample.minutes
        event = Event.new(
          id: SecureRandom.uuid,
          event_type: event_types.sample,
          occurred_at: occurred_at,
          processed_at: occurred_at + (ms.sample / 1000.0) / (24 * 60 * 60),
          )
        MetricAggregator.new(event).aggregate
      end
    end
  end
end