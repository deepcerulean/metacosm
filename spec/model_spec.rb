# TODO remove
# require 'spec_helper'
# 
# class Dog < Model
#   belongs_to :child
# end
# 
# class Child < Model
#   has_one :dog
#   belongs_to :parent
# end
# 
# class Parent < Model
#   has_many :children
#   has_many :dogs, :through => :children
# end
# 
# ###
# 
# # class Patient < Model
# #   has_many :appointments
# #   has_many :doctors, :through => :appointments
# # end
# # 
# # class Appointment < Model
# #   belongs_to :patient
# #   belongs_to :doctor
# # end
# # 
# # class Doctor < Model
# #   has_many :appointments
# #   has_many :patients, :through => :appointments
# # end
# 
# ###
# 
# describe Model do
#   subject(:model) { Model.create }
#   describe "#id" do
#     it 'should be retrievable by id' do
#       expect(Model.find(model.id)).to eq(model)
#     end
#   end
# 
#   context 'one-to-one relationships' do
#     let(:child) { Child.create }
#     let(:another_child) { Child.create }
# 
#     it 'should create children' do
#       expect { child.dog.create }.to change { Dog.count }.by(1) #from(0).to(1)
#       expect(child.dog).to eq(Dog.first)
#       # expect(dog.child.find).to eq(child)
#     end
# 
#     it 'should have inverse relationships' do
#       dog = child.dog.create
#       expect(dog.child).to eq(child)
# 
#       binding.pry
# 
#       another_dog = another_child.dog.create
#       expect(another_dog.child).to eq(another_child)
#       # expect(dog.child_id).to eq(child.id)
#     end
#   end
# 
#   context 'one-to-many relationships' do
#     let(:parent) { Parent.create }
# 
#     it 'should create children' do
#       expect { parent.children.create }.to change{ Child.count }.by(1)
#       expect(parent.children.all).to all(be_a(Child))
#     end
# 
#     xit 'should create inverse relationships' 
#   end
# 
#   context 'one-to-many through relationships' do
#     let(:parent) { Parent.create }
#     let(:child) { parent.children.create }
#     subject(:dogs) { parent.dogs }
# 
#     it 'should create children of children' do
#       child.dog.create
#       expect(dogs.all).to all(be_a(Dog))
#     end
#   end
# end
