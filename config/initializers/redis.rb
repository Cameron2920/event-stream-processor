REDIS_POOL = ConnectionPool.new(
  size: 10, # Match number of server threads
  timeout: 5
) do
  Redis.new(
    host: ENV.fetch('REDIS_HOST', 'localhost'),
    port: ENV.fetch('REDIS_PORT', 6379),
    db: ENV.fetch('REDIS_DB', 0),
    password: ENV.fetch('REDIS_PASSWORD', nil)
  )
end