class Village < Model
  def initialize(name:)
    @name = name
  end
end

class VillageView < View
  attr_reader :village_id, :world_id, :name

  def initialize(world_id:, village_id:)
    @village_id = village_id
    @world_id = world_id
  end

  def update_name(name)
    @name = name
    self
  end
end

class World < Model
  def initialize(villages: [])
    @villages = villages
  end

  def create_village!(name:)
    village = Village.create(name:name)
    @villages.push(village)

    emit(
      VillageCreatedEvent.new(
        village_id: village.id,
        village_name: name,
        world_id: self.id
      )
    )
  end
end

class WorldView < View
  attr_reader :world_id
  def initialize(world_id:)
    @world_id = world_id
  end

  def villages
    VillageView.where(world_id: world_id).all
  end
end

class CreateVillageCommand < Struct.new(:world_id, :name)
end

class CreateVillageCommandHandler
  def handle(cmd)
    world = World.find(cmd.world_id)
    world.create_village!(name: cmd.name)
  end
end

class VillageCreatedEvent
  attr_reader :world_id, :village_id, :village_name
  def initialize(world_id:,village_id:, village_name:)
    @world_id = world_id
    @village_id = village_id
    @village_name = village_name
  end
end

class VillageCreatedEventListener < EventListener
  def receive(evt)
    world_id, village_id, village_name = evt.world_id, evt.village_id, evt.village_name

    # world_view = WorldView.where(world_id: world_id).first_or_create

    village_view = VillageView.where(
      world_id: world_id, 
      village_id: village_id
    ).first_or_create

    village_view.update_name(village_name)

    # binding.pry
  end
end

class VillageNamesQuery
  def execute(world_id:)
    world = WorldView.where(world_id: world_id).first_or_create
    # binding.pry
    world.villages.map(&:name) #.value
  end
end
