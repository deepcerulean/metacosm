require 'passive_record'
require 'frappuccino'
require 'metacosm/version'

module Metacosm
  class Model
    include PassiveRecord
    after_create :register_observer, :emit_creation_event

    def update(attrs={})
      attrs.each do |k,v|
        send("#{k}=",v)
      end

      emit(updation_event(attrs)) if updated_event_class
    end

    protected
    def register_observer
      Simulation.current.watch(self)
    end

    def emit_creation_event
      emit(creation_event) if created_event_class
    end

    def attributes_with_external_id
      attrs = to_h
      if attrs.key?(:id)
        new_id_key = self.class.name.split('::').last.underscore + "_id"
        attrs[new_id_key.to_sym] = attrs.delete(:id)
      end
      attrs
    end

    # trim down extenralized attrs for evt
    def attributes_for_event(klass, additional_attrs={})
      # assume evts attrs are attr_accessible?
      keys_to_keep = klass.instance_methods.find_all do |method|
        method != :== &&
          method != :! &&
          klass.instance_methods.include?(:"#{method}=")
      end

      attributes_with_external_id.
        delete_if {|k,v| !keys_to_keep.include?(k) }.
        merge(additional_attrs)
    end

    def assemble_event(klass, addl_attrs={})
      klass.create(attributes_for_event(klass).merge(addl_attrs))
    end

    def creation_event
      assemble_event(created_event_class)
    end

    def created_event_class
      created_event_name = self.class.name + "CreatedEvent"
      Object.const_get(created_event_name) rescue nil
    end

    def updation_event(changed_attrs={})
      assemble_event(updated_event_class, changed_attrs)
    end

    def updated_event_class
      updated_event_name = self.class.name + "UpdatedEvent"
      Object.const_get(updated_event_name) rescue nil
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

    def attrs
      to_h.keep_if { |k,_| k != :id }
    end

    def ==(other)
      attrs == other.attrs
    end
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
      # binding.pry
      handler_for(command).handle(command.attrs)
    end

    def receive(event, record: true)
      events.push(event) if record

      listener = listener_for(event)
      listener.receive(event.attrs)
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
