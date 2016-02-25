module Metacosm
  class Model
    include PassiveRecord
    after_create :register_observer, :emit_creation_event
    after_update :emit_updation_event

    private
    def register_observer
      Simulation.current.watch(self)
    end

    def emit_creation_event
      emit(creation_event) if created_event_class
    end

    def emit_updation_event
      emit(updation_event) if updated_event_class
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

    def assemble_event(klass, addl_attrs={})
      klass.create(attributes_for_event(klass).merge(addl_attrs))
    end

    def creation_event
      assemble_event created_event_class
    end

    def updation_event
      assemble_event updated_event_class
    end

    def created_event_class
      created_event_name = self.class.name + "CreatedEvent"
      Object.const_get(created_event_name) rescue nil
    end

    def updated_event_class
      updated_event_name = self.class.name + "UpdatedEvent"
      Object.const_get(updated_event_name) rescue nil
    end

    def blacklisted_attribute_names
      [ :@observer_peers ]
    end
  end
end
