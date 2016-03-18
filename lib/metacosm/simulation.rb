require 'drb/drb'
module Metacosm
  class EventStream < Frappuccino::Stream
    include DRb::DRbUndumped
  end

  class Simulation
    attr_accessor :running
    def watch(model)
      Frappuccino::Stream.new(model).on_value(&method(:receive))
    end

    def fire(command)
      command_queue.push(command)
    end

    def command_queue
      @command_queue ||= Queue.new
    end

    def conduct!
      @conductor_thread = Thread.new { execute }
    end

    def execute
      while true
        if (command=command_queue.pop)
          apply(command)
        else
          thread.pass
          sleep 0.001
        end
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
        handler = handler_for(command)
        handler.handle(command.attrs)
      end
    end

    def event_stream
      @event_stream ||= EventStream.new(self)
    end

    def has_event_stream?
      !@event_stream.nil?
    end

    def receive(event, record: true)
      if record
        events.push(event) 
        emit(event) if has_event_stream?
      end

      listener = listener_for(event)
      if event.attrs.any?
        listener.receive(event.attrs)
      else
        listener.receive
      end
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
      # module_name = "Object" if module_name.empty?
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
      module_name = event.listener_module_name #class.name.deconstantize
      # module_name = "Object" if module_name.empty?
      listener = (module_name.constantize).const_get(event.listener_class_name).new(self)
      listener
    end
  end
end
