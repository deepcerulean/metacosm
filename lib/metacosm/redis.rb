require 'connection_pool'

REDIS = ConnectionPool.new(size: 3) do
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

