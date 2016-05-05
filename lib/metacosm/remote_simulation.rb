module Metacosm
  class RemoteSimulation < Simulation
    def initialize(command_queue, event_stream)
      @command_queue_name = command_queue
      @event_stream_name  = event_stream
      setup_connection
    end

    def apply(command); fire command end

    def fire(command)
      puts "---> Firing command at remote sim..."
      command_dto = command.attrs.merge(handler_module: command.handler_module_name, handler_class_name: command.handler_class_name)
      redis = redis_connection

      puts "---> Sending command over redis conn: #{redis.inspect}"
      redis.publish(@command_queue_name, Marshal.dump(command_dto))
      puts "---> Sent!"
      true
    end

    def received_events
      @events_received ||= []
    end

    def setup_connection
      @remote_listener_thread = Thread.new do
        begin
          redis = redis_connection
          redis.subscribe(@event_stream_name) do |on|
            on.subscribe do |channel, subscriptions|
              puts "Subscribed to remote simulation event stream ##{channel} (#{subscriptions} subscriptions)"
            end

            on.message do |channel, message|
              event = Marshal.load(message)
              listener_module_name = event.delete(:listener_module)
              listener_class_name = event.delete(:listener_class_name)
              module_name = listener_module_name
              module_name = "Object" if module_name.empty?
              listener = (module_name.constantize).const_get(listener_class_name).new(self)
              listener.receive(event)

              received_events.push(event)
            end

            on.unsubscribe do |channel, subscriptions|
              puts "Unsubscribed from remote simulation event stream ##{channel} (#{subscriptions} subscriptions)"
            end
          end
        rescue ::Redis::BaseConnectionError => error
          puts "#{error}, retrying in 1s"
          sleep 1
          retry
        end
      end
    end
  end
end
