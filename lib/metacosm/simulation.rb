module Metacosm
  class Simulation
    def watch(model)
      Frappuccino::Stream.new(model).on_value(&method(:receive))
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
