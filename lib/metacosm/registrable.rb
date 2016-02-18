module Metacosm
  module Registrable
    class Query < Struct.new(:klass, :conditions)
      def all
        klass.all.select do |instance|
          conditions.all? do |(field,value)|
            instance.send(field) == value
          end
        end
      end

      def first
        all.first
      end

      def create
        klass.create(conditions)
      end

      def first_or_create
        first || create
      end
    end

    class Identifier < Struct.new(:value)
      def self.generate
        new(SecureRandom.uuid)
      end
    end

    def instances_by_id
      @instances ||= {}
    end

    def register(model)
      instances_by_id[model.id] = model
    end

    def all
      instances_by_id.values
    end

    def find_by_id(id)
      instances_by_id[id]
    end

    def find_by_ids(ids)
      instances_by_id.select { |id,_| ids.include?(id) }.values
    end

    def find(conditions)
      if conditions.is_a?(Identifier)
        find_by_id(conditions)
      elsif conditions.is_a?(Array) && conditions.all? { |c| c.is_a?(Identifier) }
        find_by_ids(conditions)
      else
        where(conditions).first
      end
    end

    def where(conditions)
      Query.new(self, conditions)
    end

    def create(*args)
      registrable = new(*args)

      registrable.singleton_class.class_eval { attr_accessor :id }
      registrable.send(:"id=", Identifier.generate)
      register(registrable)

      registrable
    end
  end
end
