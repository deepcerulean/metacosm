require 'passive_record'
require 'frappuccino'

require 'metacosm/version'
require 'metacosm/model'
require 'metacosm/simulation'

Thread.abort_on_exception=true

module Metacosm
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

    def handler_class_name
      self.class.name.demodulize + "Handler"
    end

    def handler_module_name
      module_name = self.class.name.deconstantize
      module_name = "Object" if module_name.empty?
      module_name
    end

    def self_class_name
      self.class.name
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

    def listener_class_name
      self.class.name.demodulize + "Listener"
    end

    def listener_module_name
      module_name = self.class.name.deconstantize
      module_name = "Object" if module_name.empty?
      module_name
    end

    def self_class_name
      self.class.name
    end
  end

  class EventListener < Struct.new(:simulation)
    def fire(command)
      self.simulation.fire(command)
    end
  end
end
