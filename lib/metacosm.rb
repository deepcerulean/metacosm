require 'passive_record'
# require 'passive_record/hstruct'
require 'frappuccino'

# require 'active_support/core_ext/string/inflections'

require 'metacosm/version'
require 'metacosm/hstruct'

module Metacosm
  class Model
    include PassiveRecord
    after_create { Simulation.current.watch(self) }
  end

  class View
    include PassiveRecord
  end

  # class Event
  #   include PassiveRecord
  # end

  class Command
    include PassiveRecord
  end

  class EventListener
    attr_reader :simulation

    def initialize(sim)
      @simulation = sim
    end

    def fire(command)
      simulation.apply(command)
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

    def receive(event)
      events.push(event)

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
    def listener_for(event)
      @listeners ||= {}
      @listeners[event] ||= construct_listener_for(event)
    end

    # TODO should commands handlers also be event sources?
    def handler_for(command)
      @handlers ||= {}
      @handlers[command] ||= Object.const_get(command.class.name.split('::').last + "Handler").new
    end

    def construct_listener_for(event)
      listener = Object.const_get(event.class.name.split('::').last + "Listener").
        new(self)

      # TODO should we receive events from listeners?
      # listener_stream = Frappuccino::Stream.new(listener)
      # listener_stream.on_value(&method(:receive))
      listener
    end
  end
end
