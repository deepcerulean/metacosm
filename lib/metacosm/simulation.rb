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
        handler_for(command).handle(command.attrs)
      end
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
      @command_queue&.clear
    end

    protected
    def handler_for(command)
      @handlers ||= {}
      @handlers[command.class] ||= construct_handler_for(command)
    end

    def construct_handler_for(command)
      module_name = command.class.name.deconstantize
      module_name = "Object" if module_name.empty?
      (module_name.constantize).
        const_get(command.class.name.demodulize + "Handler").new
    end

    def listener_for(event)
      @listeners ||= {}
      @listeners[event.class] ||= construct_listener_for(event)
    end

    def construct_listener_for(event)
      module_name = event.class.name.deconstantize
      module_name = "Object" if module_name.empty?
      listener = (module_name.constantize).const_get(event.class.name.demodulize + "Listener").new(self)
      listener
    end
  end
end
