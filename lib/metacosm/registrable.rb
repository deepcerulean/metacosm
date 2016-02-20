# require 'metacosm/registrable/query'
# require 'metacosm/registrable/identifier'
# require 'metacosm/registrable/has_one_association'
# require 'metacosm/registrable/has_many_association'
# require 'metacosm/registrable/has_many_through_association'
# require 'metacosm/registrable/belongs_to_association'
# 
# module Metacosm
#   module Registrable
#     def instances_by_id
#       @instances ||= {}
#     end
# 
#     def register(model)
#       instances_by_id[model.id] = model
#       self
#     end
# 
#     def associations
#       @associations ||= []
#     end
# 
#     def belongs_to(parent_name_sym)
#       target_class_name = (parent_name_sym.to_s).split('_').map(&:capitalize).join
# 
#       association = BelongsToAssociation.new(self, target_class_name)
#       associations.push(association)
# 
#       define_method(parent_name_sym) { association.find || association }
#       define_method(parent_name_sym.to_s + "_id") { association.id }
#       define_method(parent_name_sym.to_s + "_id=") { |new_id| association.id = new_id }
#     end
# 
#     def has_one(child_name_sym)
#       target_class_name = (child_name_sym.to_s).split('_').map(&:capitalize).join
#       target_class = Object.const_get(target_class_name)
# 
#       association = HasOneAssociation.new(self, target_class)
#       associations.push(association)
# 
#       define_method(child_name_sym) { association.parent_id ||= self.id; association.find || association }
#       define_method(child_name_sym.to_s + "_id") { association.id }
#     end
# 
#     def has_many(collection_name_sym, opts={})
#       target_class_name = (collection_name_sym.to_s).split('_').map(&:capitalize).join
#       target_class = Object.const_get(target_class_name.singularize)
#       if opts[:through]
#         through_class_name = (opts[:through].to_s).split('_').map(&:capitalize).join
#         through_class = Object.const_get(through_class_name.singularize)
#         base_association = associations.detect { |assn| assn.target_klass == through_class }
#         raise "No such association with #{through_class}" unless base_association
# 
#         association = HasManyThroughAssociation.new(
#           base_association,
#           target_class,
#           collection_name_sym
#         )
# 
#         associations.push(association)
# 
#         define_method(collection_name_sym) { association }
#         define_method(collection_name_sym.to_s + "_ids") { association.ids }
#       else
#         association = HasManyAssociation.new(self, target_class)
# 
#         associations.push(association)
# 
#         define_method(collection_name_sym) { association }
#         define_method(collection_name_sym.to_s + "_ids") { association.ids }
#       end
#     end
# 
#     def all
#       instances_by_id.values
#     end
# 
#     def count
#       all.count
#     end
# 
#     def first
#       all.first
#     end
# 
#     def last
#       all.last
#     end
# 
#     def find_by_id(id)
#       instances_by_id[id]
#     end
# 
#     def find_by_ids(ids)
#       instances_by_id.select { |id,_| ids.include?(id) }.values
#     end
# 
#     def find(conditions)
#       if conditions.is_a?(Identifier)
#         find_by_id(conditions)
#       elsif conditions.is_a?(Array) && conditions.all? { |c| c.is_a?(Identifier) }
#         find_by_ids(conditions)
#       else
#         where(conditions).first
#       end
#     end
# 
#     def where(conditions)
#       Query.new(self, conditions)
#     end
# 
#     def create(*args)
#       registrable = new(*args)
# 
#       registrable.singleton_class.class_eval { attr_accessor :id }
#       registrable.send(:"id=", Identifier.generate)
#       register(registrable)
# 
#       registrable
#     end
#   end
# end
