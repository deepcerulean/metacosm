require 'passive_record'
require 'frappuccino'
require 'metacosm/version'

module Metacosm
  class Model
    include PassiveRecord
    after_create { Simulation.current.watch(self) }
  end

  class View
    include PassiveRecord
  end

  class EventListener < Struct.new(:simulation)
    def fire(command)
      self.simulation.apply(command)
    end
  end

  class Simulation
    def watch(model)
      model_events ||= []
      model_event_stream = Frappuccino::Stream.new(model)
      model_event_stream.on_value do |event|
        receive(event)
      end
    end

    def apply(command)
      handler_for(command).handle(command)
    end

    def receive(event, record: true)
      events.push(event) if record

      listener = listener_for(event)
      listener.receive(event)
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
