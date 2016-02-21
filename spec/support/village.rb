class Person < Model
  belongs_to :village
  attr_accessor :name
  after_create { emit created_event }

  def created_event
    PersonCreatedEvent.create(
      person_name: self.name,
      village_id: self.village_id,
      person_id: self.id
    )
  end
end

class PersonView
  include PassiveRecord
  attr_accessor :person_name, :person_id, :village_id
  belongs_to :village_view
end

class Village < Model
  attr_accessor :name
  belongs_to :world
  has_many :people
  after_create { emit created_event }

  def created_event
    VillageCreatedEvent.new(
      self.world_id,
      self.id,
      self.name,
    )
  end
end

class VillageView < View
  belongs_to :world_view
  has_many :person_views

  attr_accessor :name, :village_id, :world_id
end

class World < Model
  has_many :villages

  def populate!(name_dictionary)
    villages.each do |village|
      village.create_person(name: name_dictionary.sample)
    end
  end
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

class VillageCreatedEvent < Struct.new(:world_id, :village_id, :village_name)
end

class VillageCreatedEventListener < EventListener
  def receive(evt)
    world_id, village_id, village_name =
      evt.world_id, 
      evt.village_id,
      evt.village_name

    world = WorldView.where(world_id: world_id).first_or_create
    world.create_village_view(world_id: world_id, village_id: village_id, name: village_name)
  end
end

class PopulateCommand < Struct.new(:world_id, :name_dictionary); end

class PopulateCommandHandler
  def handle(cmd)
    world = World.find(cmd.world_id)
    world.populate!(cmd.name_dictionary)
  end
end

class PersonCreatedEvent < Struct.new(:village_id, :person_id, :person_name)
end

class PersonCreatedEventListener < EventListener
  def receive(evt)
    person_name, person_id, village_id = evt.person_name, evt.person_id, evt.village_id
    village_view = VillageView.where(village_id: village_id).first
    village_view.create_person_view(
      person_name: person_name,
      person_id: person_id,
      village_id: village_id
    )
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
  def execute #(world_id:)
    world_view = WorldView.where(world_id: world_id).first_or_create
    world_view.person_views.flat_map(&:person_name)
  end
end
