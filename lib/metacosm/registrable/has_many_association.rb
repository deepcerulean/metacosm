module Metacosm
  module Registrable
    class HasManyAssociation < Struct.new(:klass, :target_klass)
      def ids
        @associated_ids ||= []
      end

      def create(*args)
        model = target_klass.create(*args)
        ids.push model.id
        model
      end

      def first
        target_klass.find(ids.first)
      end

      def last
        target_klass.find(ids.last)
      end

      def all(*args)
        target_klass.find(ids)
      end
    end
  end
end
