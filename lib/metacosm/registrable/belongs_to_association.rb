module Metacosm
  module Registrable
    class BelongsToAssociation < Struct.new(:child_class, :parent_class_name)
      def id
        @associated_id ||= nil
      end

      def id=(_id)
        @associated_id = _id
      end

      def find
        # binding.pry
        parent_class.find(id)
      end

      def parent_class
        Object.const_get(parent_class_name)
      end
    end
  end
end
