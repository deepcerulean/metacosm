class Person < Model
  belongs_to :village
  attr_accessor :name
end

class PersonView < View
  belongs_to :village_view
  attr_accessor :person_name, :person_id, :village_id
end

class Village < Model
  belongs_to :world
  has_many :people
  attr_accessor :name
end

class VillageView < View
  belongs_to :world_view
  has_many :person_views
  attr_accessor :name, :village_id, :world_id
end

class World < Model
  has_many :villages
  has_many :people, :through => :villages
end

class WorldView < View
  attr_accessor :world_id
  has_many :village_views
  has_many :person_views, :through => :village_views
end

class CreateVillageCommand < Struct.new(:world_id, :village_id, :village_name)
end

class CreateVillageCommandHandler
  def handle(cmd)
    world = World.where(id: cmd.world_id).first_or_create
    world.create_village(name: cmd.village_name, id: cmd.village_id)
    self
  end
end

class VillageCreatedEvent < Event
  attr_accessor :village_id, :name, :world_id
end

class VillageCreatedEventListener < EventListener
  def receive(world_id:, village_id:, name:)
    world = WorldView.where(world_id: world_id).first_or_create
    world.create_village_view(
      world_id: world_id, 
      village_id: village_id, 
      name: name
    )
  end
end

class CreatePersonCommand < Struct.new(:world_id, :village_id, :person_id, :person_name); end

class CreatePersonCommandHandler
  def handle(cmd)
    world = World.where(id: cmd.world_id).first_or_create
    world.create_person(id: cmd.person_id, village_id: cmd.village_id, name: cmd.person_name)
  end
end

class PersonCreatedEvent < Event
  attr_accessor :name, :person_id, :village_id
end

class PersonCreatedEventListener < EventListener
  def receive(name:, person_id:, village_id:)
    village_view = VillageView.where(village_id: village_id).first
    village_view.create_person_view(
      person_name: name,
      person_id: person_id,
      village_id: village_id
    )
  end
end

class PopulateWorldCommand < Struct.new(:world_id, :name_dictionary, :per_village); end
class PopulateWorldCommandHandler
  def handle(cmd)
    world_id   = cmd.world_id
    dictionary = cmd.name_dictionary

    world = World.where(id: world_id).first_or_create

    world.villages.each do |village|
      name = dictionary.sample
      cmd.per_village.times do
        village.create_person(name: name)
      end
    end
  end
end

class CreateWorldCommand < Struct.new(:world_id); end
class CreateWorldCommandHandler
  def handle(cmd)
    world_id = cmd.world_id
    World.create(id: world_id)
  end
end

## queries

class VillageNamesQuery < Struct.new(:world_id)
  def execute
    world = WorldView.where(world_id: world_id).first_or_create
    world.village_views.map(&:name)
  end
end

class PeopleNamesQuery < Struct.new(:world_id)
  def execute
    world_view = WorldView.where(world_id: world_id).first_or_create
    world_view.person_views.flat_map(&:person_name)
  end
end

## experiment driver

# class CivilizationExperiment # < Experiment
#   def before
#     fire create_world #(CreateWorldCommand.new)
#   end
# 
#   def step
#     fire simulate_year #(SimulateYearCommand.new)
#   end
# 
#   def create_world
#     CreateWorldCommand
#   end
# end
