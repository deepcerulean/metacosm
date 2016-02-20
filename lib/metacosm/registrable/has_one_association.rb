module Metacosm
  module Registrable
    class HasOneAssociation < Struct.new(:parent_class, :child_class)
      attr_writer :parent_id

      def id
        @associated_id ||= nil
      end

      def parent_id
        @parent_id ||= nil
      end

      def create(*args)
        model = child_class.create(*args)
        # @associated_id = model.id
        model.send("#{parent_class_name}_id=", parent_id)
        model
      end

      def find
        # target_klass.find(id)
        child_class.find(:"#{parent_class_name}_id" => parent_id)
      end

      def parent_class_name
        parent_class.name.underscore
      end
    end
  end
end
