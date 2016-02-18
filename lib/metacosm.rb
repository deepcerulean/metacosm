require 'frappuccino'

require 'metacosm/version'
require 'metacosm/registrable'

module Metacosm
  class Model
    extend Registrable
  end

  class View
    extend Registrable
  end

  class EventListener
    def initialize(simulation)
      @simulation = simulation
    end

    def fire(command)
      @simulation.apply(command)
    end
  end

  class Simulation
    attr_reader :model, :model_events

    def initialize(model)
      @model = model
      @model_events ||= []
      @model_event_stream = Frappuccino::Stream.new(model)
      @model_event_stream.on_value do |event|
        @model_events << event
        receive(event)
      end
    end

    def apply(command)
      handler_for(command).handle(command)
    end

    def receive(event)
      listener = listener_for(event)
      listener.receive(event)
    end

    def listener_for(event)
      @listeners ||= {}
      @listeners[event] ||= construct_listener_for(event)
    end

    def construct_listener_for(event)
      listener = Object.const_get(event.class.name.split('::').last + "Listener").new(self)

      # TODO some test which verifies we can receive events from
      #      listeners
      # listener_stream = Frappuccino::Stream.new(listener)
      # listener_stream.on_value(&method(:receive))
      listener
    rescue
      binding.pry
    end

    # TODO commands handlers can also probably be event sources
    #      although this seems weird with the cases we are looking
    #      at right now
    def handler_for(command)
      @handlers ||= {}
      @handlers[command] ||= Object.const_get(command.class.name.split('::').last + "Handler").new
    end
  end
end
