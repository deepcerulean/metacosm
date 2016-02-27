module Metacosm
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
      @running = true
      @conductor_thread = Thread.new { execute }
    end

    def execute
      while @running
        if (command=command_queue.pop)
          # p [ :applying!, command: command ]
          apply(command)
        end
        sleep 0.01
      end
    end

    def halt!
      @running = false
      @conductor_thread.terminate
    end

    def apply(command)
      handler_for(command).handle(command.attrs)
    end

    def receive(event, record: true)
      events.push(event) if record

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
    end

    protected
    def handler_for(command)
      @handlers ||= {}
      @handlers[command] ||= Object.const_get(command.class.name.split('::').last + "Handler").new
    end

    def listener_for(event)
      @listeners ||= {}
      @listeners[event] ||= construct_listener_for(event)
    end

    def construct_listener_for(event)
      listener = Object.const_get(event.class.name.split('::').last + "Listener").new(self)
      listener
    end
  end
end
