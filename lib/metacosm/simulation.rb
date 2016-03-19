module Metacosm
  class Simulation
    def fire(command)
      command_queue.push(command)
    end

    def command_queue
      @command_queue ||= Queue.new
    end

    def event_queue
      @event_queue ||= Queue.new
    end

    def conduct!
      @conductor_thread = Thread.new { execute }
    end

    def execute
      while true
        if (command=command_queue.pop)
          apply(command)
          sleep 0.01
        end
        Thread.pass
      end
    end

    def halt!
      @conductor_thread.terminate
    end

    def mutex
      @mutex = Mutex.new
    end

    def apply(command)
      mutex.synchronize do
        if command.is_a?(Hash)
          handler_module_name = command.delete(:handler_module)
          handler_class_name = command.delete(:handler_class_name)
          module_name = handler_module_name
          handler = (module_name.constantize).
            const_get(handler_class_name).new
          handler.handle(command)
        else
          handler = handler_for(command)
          handler.handle(command.attrs)
        end
      end
    end

    def apply_event(event)
      if !@on_event_callback.nil?
        event_dto = event.attrs.merge(listener_module: event.listener_module_name, listener_class_name: event.listener_class_name)
        @on_event_callback[event_dto]
      end

      if !@event_publication_channel.nil?
        event_dto = event.attrs.merge(listener_module: event.listener_module_name, listener_class_name: event.listener_class_name)
        redis = Redis.new
        redis.publish(@event_publication_channel, Marshal.dump(event_dto))
      end

      if !local_events_disabled?
        listener = listener_for(event)
        if event.attrs.any?
          listener.receive(event.attrs)
        else
          listener.receive
        end
      end
    end

    def on_event(publish_to:nil,&blk)
      unless publish_to.nil?
        @event_publication_channel = publish_to
      end

      if block_given?
        @on_event_callback = blk
      end
    end

    def subscribe_for_commands(channel:)
      p [ :subscribe_to_command_channel, channel: channel ]
      redis = Redis.new
      begin
	redis.subscribe(channel) do |on|
          on.subscribe do |chan, subscriptions|
	    puts "Subscribed to ##{chan} (#{subscriptions} subscriptions)"
	  end

	  on.message do |chan, message|
	    puts "##{chan}: #{message}"
            apply(Marshal.load(message))
	  end

	  on.unsubscribe do |chan, subscriptions|
	    puts "Unsubscribed from ##{chan} (#{subscriptions} subscriptions)"
	  end
	end
      rescue Redis::BaseConnectionError => error
	puts "#{error}, retrying in 1s"
	sleep 1
	retry
      end
    end

    def disable_local_events
      @local_events_disabled = true
    end

    def local_events_disabled?
      @local_events_disabled ||= false
    end

    def receive(event, record: true)
      events.push(event) if record
      apply_event(event)
    end

    def events
      @events ||= []
    end

    def self.current
      @current ||= new
    end

    def clear!
      @events = []
      @command_queue&.clear
    end

    protected
    def handler_for(command)
      @handlers ||= {}
      @handlers[command.self_class_name] ||= construct_handler_for(command)
    end

    def construct_handler_for(command)
      module_name = command.handler_module_name
      (module_name.constantize).
        const_get(command.handler_class_name).new
    rescue => ex
      binding.pry
      raise ex
    end

    def listener_for(event)
      @listeners ||= {}
      @listeners[event.self_class_name] ||= construct_listener_for(event)
    end

    def construct_listener_for(event)
      module_name = event.listener_module_name
      listener = (module_name.constantize).const_get(event.listener_class_name).new(self)
      listener
    end
  end
end
