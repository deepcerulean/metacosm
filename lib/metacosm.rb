require 'passive_record'
require 'frappuccino'
require 'metacosm/version'

module Metacosm
  class Model
    include PassiveRecord
    after_create { 
      Simulation.current.watch(self) # move to before_create?
      # binding.pry if self.class == Village
      emit(created_event) if created_event_class #self.class.creation_event.new(self.to_h))
    }

    # after_update  { emit updated_event }
    # after_destroy { emit destroyed_event }

    protected
    def attributes_with_external_id
      attrs = to_h
      if attrs.key?(:id)
        new_id_key = self.class.name.split('::').last.underscore + "_id"
        attrs[new_id_key.to_sym] = attrs.delete(:id)
      end
      attrs
    end

    # trim down extenralized attrs for evt
    def attributes_for_event(klass)
      # assume evts attrs are attr_accessible? 
      keys_to_keep = klass.instance_methods.find_all do |method|
        method != :== &&
          method != :! &&
          klass.instance_methods.include?(:"#{method}=")
      end

      attributes_with_external_id.
        delete_if {|k,v| !keys_to_keep.include?(k) }
    end

    def assemble_event(klass)
      klass.create(attributes_for_event(klass))
    end

    def created_event
      assemble_event(created_event_class)
    end

    def created_event_class
      created_event_name = self.class.name + "CreatedEvent"
      Object.const_get(created_event_name) rescue nil
    end

    def blacklisted_attribute_names
      [ :@observer_peers ]
    end
  end

  class View
    include PassiveRecord
  end

  class Command
    include PassiveRecord
  end

  class Event
    include PassiveRecord

    def attrs
      to_h.keep_if { |k,_| k != :id }
    end

    def ==(other)
      attrs == other.attrs
    end
  end

  class EventListener < Struct.new(:simulation)
    def fire(command)
      self.simulation.apply(command)
    end
  end

  class Simulation
    def watch(model)
      Frappuccino::Stream.new(model).on_value(&method(:receive))
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

  # class Experiment
  #   def self.conduct
  #     experiment = new
  #     experiment.before
  #     experiment.conduct
  #     experiment.after
  #     experiment
  #   end

  #   def before_step
  #   end

  #   def before
  #   end

  #   def after
  #   end

  #   def after_step
  #   end

  #   def step
  #   end

  #   protected
  #   def concluded?
  #     @concluded ||= false
  #   end

  #   def conclude!
  #     @concluded = true
  #   end

  #   private
  #   def conduct
  #     iterate until concluded?
  #   end

  #   def iterate
  #     before_step
  #     step
  #     after_step
  #   end
  # end
end
