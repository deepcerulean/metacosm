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
      self.simulation.fire(command)
    end
  end
end
