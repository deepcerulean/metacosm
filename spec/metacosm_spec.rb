require 'spec_helper'

describe "a simple simulation (fizzbuzz)" do
  subject(:simulation) { Simulation.current }
  let!(:model) { Counter.create }
  let(:last_event) { simulation.events.last }

  describe "#apply" do
    let(:increment_counter) do
      IncrementCounterCommand.new(1, model.id)
    end

    context "one command once" do
      before { simulation.apply(increment_counter) }

      describe "the last event" do
        subject { last_event }
        it { is_expected.to be_a CounterIncrementedEvent }
        its(:counter_id) { is_expected.to eql(model.id) }
        its(:counter_value) { is_expected.to eq(1) }
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

    context "one command ten times" do
      it 'is expected to play fizz buzz' do
        expect {
          10.times { simulation.apply(increment_counter) }
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
          it { is_expected.to be_a BuzzEvent }
          its(:counter_id) { is_expected.to eql(model.id) }
          its(:value) { is_expected.to eq(n) }
        end

        describe "querying for the counter value" do
          let(:counter_value_query) do
            CounterValueQuery.new
          end

          subject do
            counter_value_query.execute(counter_id: model.id)
          end

          it { is_expected.to eq(n) } #"The counter is at 1") }
        end
      end

      context 'with concurrent command sources' do
        let(:m) { 2 }       # fibers
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

        describe "the last event" do
          subject { last_event }

          it { is_expected.to be_a BuzzEvent }
          its(:counter_id) { is_expected.to eql(model.id) }
          its(:value) { is_expected.to eq(n) }
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
  let!(:world) { World.create(id: world_id) }
  let(:world_id) { 'world_id' }

  describe "#apply" do
    context 'create and populate villages' do
      let(:person_id) { 'person_id' }
      let(:village_id) { 'village_id' }
      let(:village_name) { 'Oakville Ridge' }

      let(:people_per_village)  { 10 }

      let(:create_village_command) do
        CreateVillageCommand.new(world_id, village_id, village_name)
      end

      let(:village_created_event) do
        VillageCreatedEvent.create(world_id: world_id, village_id: village_id, name: village_name)
      end

      let(:populate_world_command) do
        PopulateWorldCommand.new(world_id, %w[ Alice ], people_per_village)
      end
      #
      let(:create_person_command) do
        CreatePersonCommand.new(world_id, village_id, person_id, "Alice")
      end

      let(:person_created_event) do
        PersonCreatedEvent.create(village_id: village_id, person_id: person_id, name: "Alice")
      end

      let(:village_names_query) do
        VillageNamesQuery.new(world_id)
      end

      let(:people_names_query) do
        PeopleNamesQuery.new(world_id)
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
    end
  end
end
