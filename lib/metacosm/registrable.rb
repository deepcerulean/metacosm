module Metacosm
  module Registrable
    def instances
      @instances ||= []
    end

    def register(model)
      instances.push(model)
      instances.length
    end

    def lookup(id)
      instances.find { |m| m.id == id }
    end

    def create(*args)
      registrable = new(*args)
      registrable.singleton_class.class_eval { attr_accessor :id }
      registrable.send(:"id=", register(registrable))
      registrable
    end
  end
end
