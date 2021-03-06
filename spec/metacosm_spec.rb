require 'spec_helper'

describe "a simple simulation (fizzbuzz)" do
  subject(:simulation) { Simulation.current }
  let!(:model) { Counter.create }
  let(:last_event) { simulation.events.last }

  describe "#apply" do
    let(:increment_counter) do
      IncrementCounterCommand.create(
        increment: 1, counter_id: model.id
      )
    end

    let(:counter_incremented) do
      CounterIncrementedEvent.create(
        counter_id: model.id, value: 1
      )
    end

    it 'should run the linearized test for the README' do
      sim = Simulation.current
      sim.conduct!

      counter_model = Counter.create
      counter_view = CounterView.find_by(counter_id: counter_model.id)
      expect(counter_view.value).to eq(0) # => 0

      increment_counter_command = IncrementCounterCommand.create(
        increment: 1, counter_id: counter_model.id
      )

      sim.fire(increment_counter_command)

      sleep 0.1
      expect(counter_view.value).to eq(1) # => 1
      sim.halt!
    end

    context "one command once" do
      before { simulation.apply(increment_counter) }

      describe "the last event" do
        subject { last_event }
        it { is_expected.to be_a CounterIncrementedEvent }
        its(:counter_id) { is_expected.to eql(model.id) }
        its(:value) { is_expected.to eq(1) }
      end

      describe "querying for the counter value" do
        let(:counter_value_query) do
          CounterValueQuery.new
        end

        subject do
          counter_value_query.execute(counter_id: model.id)
        end

        it { is_expected.to eq(1) }
      end
    end

    context "one command once (spec harness style)" do
      before { model }
      subject(:command) { increment_counter }
      it { is_expected.to trigger_event(counter_incremented) }
    end

    context "one command ten times" do
      it 'is expected to play fizz buzz' do
        simulation.conduct!
        expect {
          10.times { simulation.fire(increment_counter); sleep 0.1 }
        }.to output(%w[ 1 2 fizz 4 buzz fizz 7 8 fizz buzz ].join("\n") + "\n").to_stdout
      end
    end

    context "one command repeatedly" do
      let(:n) { 10 } # ops

      context 'with a single command source' do
        before do
          n.times { simulation.apply(increment_counter) }
        end

        describe "the last event" do
          subject { last_event }
          it { is_expected.to be_a CounterIncrementedEvent }
        end

        describe "querying for the counter value" do
          let(:counter_value_query) do
            CounterValueQuery.new
          end

          subject do
            counter_value_query.execute(counter_id: model.id)
          end

          it { is_expected.to eq(n) }
        end
      end

      context 'with concurrent command sources' do
        let(:m) { 5 }
        let(:threads) {
          ts = []
          m.times do
            ts.push(Thread.new do
              (n/m).times { simulation.apply(increment_counter) }
            end)
          end
          ts
        }

        before do
          threads.map(&:join)
        end

        xdescribe "the last event" do
          subject { last_event }

          it { is_expected.to be_a BuzzEvent }
        end

        describe "querying for the counter value" do
          let(:counter_value_query) do
            CounterValueQuery.new
          end

          subject do
            counter_value_query.execute(counter_id: model.id)
          end

          it { is_expected.to eq(n) }
        end
      end
    end
  end
end

describe "a more complex simulation (village)" do
  subject(:simulation) { Simulation.current }
  let!(:world) { Village::World.create(id: world_id) }
  let(:world_id) { 'world_id' }

  describe "#apply" do
    context 'create and populate villages' do
      let(:person_id)    { 'person_id' }
      let(:village_id)   { 'village_id' }
      let(:village_name) { 'Oakville Ridge' }

      let(:people_per_village)  { 10 }

      let(:create_village_command) do
        Village::CreateVillageCommand.create(
          world_id: world_id,
          village_id: village_id,
          village_name: village_name
        )
      end

      let(:rename_village_command) do
        Village::RenameVillageCommand.create(
          village_id: village_id,
          new_village_name: "Newcity"
        )
      end

      let(:village_created_event) do
        Village::VillageCreatedEvent.create(
          world_id: world_id,
          village_id: village_id,
          name: village_name
        )
      end

      let(:populate_world_command) do
        Village::PopulateWorldCommand.create(
          world_id: world_id,
          name_dictionary: %w[ Alice ],
          per_village: people_per_village
        )
      end
      #
      let(:create_person_command) do
        Village::CreatePersonCommand.create(
          world_id: world_id,
          village_id: village_id,
          person_id: person_id,
          person_name: "Alice"
        )
      end

      let(:person_created_event) do
        Village::PersonCreatedEvent.create(village_id: village_id, person_id: person_id, name: "Alice")
      end

      let(:village_names_query) do
        Village::VillageNamesQuery.new(world_id)
      end

      let(:people_names_query) do
        Village::PeopleNamesQuery.new(world_id)
      end

      describe "handling a create village command" do
        it 'should result in a village creation event' do
          given_no_activity.
            when(create_village_command).expect_events([village_created_event])
        end
      end

      describe 'recieving a village created event' do
        it 'should create a village view we can lookup' do
          given_events([village_created_event]).
            expect_query(village_names_query, to_find: ["Oakville Ridge"])
        end
      end

      it 'should create a village and a person' do
        given_no_activity.
          when(create_village_command, create_person_command).
            expect_events([village_created_event, person_created_event]).
            expect_query(village_names_query, to_find: ["Oakville Ridge"]).
            expect_query(people_names_query, to_find: ["Alice"])
      end

      it 'should populate the world' do
        expected_names = Array.new(people_per_village) { "Alice" }

        given_no_activity.
          when(create_village_command, populate_world_command).
          expect_query(village_names_query, to_find: ["Oakville Ridge"]).
          expect_query(people_names_query, to_find: expected_names)
      end

      it 'should rename a village' do
        given_no_activity.
          when(
            create_village_command,
            rename_village_command
          ).expect_query(village_names_query, to_find: ["Newcity"])
      end
    end
  end
end
