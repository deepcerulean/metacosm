module Metacosm
  module Registrable
    class HasManyThroughAssociation < Struct.new(:base_association, :target_class, :resource_name)
      def all
        base_association.all.
          map(&resource_name.to_s.singularize.to_sym).
          map(&:find)
      end
    end
  end
end
