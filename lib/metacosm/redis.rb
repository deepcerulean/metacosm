require 'connection_pool'
CONN_POOL = 5

REDIS_PUB = ConnectionPool.new(size: CONN_POOL) do
  if ENV['REDISTOGO_URL']
    puts "---> using redis to go!"
    uri = URI.parse(ENV["REDISTOGO_URL"])
    puts "---> parsed uri: #{uri}"
    Redis.new(:host => uri.host, :port => uri.port, :password => uri.password, :thread_safe => true)
  else
    puts "---> using default redis settings..."
    Redis.new
  end
end

REDIS_SUB = ConnectionPool.new(size: CONN_POOL) do
  if ENV['REDISTOGO_URL']
    puts "---> using redis to go!"
    uri = URI.parse(ENV["REDISTOGO_URL"])
    puts "---> parsed uri: #{uri}"
    Redis.new(:host => uri.host, :port => uri.port, :password => uri.password, :thread_safe => true)
  else
    puts "---> using default redis settings..."
    Redis.new
  end
end

