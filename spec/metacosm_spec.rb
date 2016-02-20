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
  let!(:world) { World.create }

  describe "#apply" do
    context 'create and populate villages' do
      let(:create_village_command) do
        CreateVillageCommand.create(world_id: world.id, village_name: "Oakville Ridge")
      end

      let(:populate_command) do
        PopulateCommand.new(world.id, %w[ Alice ])
      end

      let(:village_names_query) do
        VillageNamesQuery.new.execute(world_id: world.id)
      end

      let(:people_names_query) do
        PeopleNamesQuery.new.execute(world_id: world.id)
      end

      # it 'should make a person' do

      it 'should make a village' do
        simulation.apply(create_village_command)
        expect(village_names_query).to eq(['Oakville Ridge'])
        expect(simulation.events.last).to be_a(VillageCreatedEvent)
        expect(simulation.events.last.village_name).to eq("Oakville Ridge")
      end

      let(:villages) { world.instance_variable_get('@villages') }
      let(:people)   { villages.first.instance_variable_get("@people") }

      it 'should create and populate a village' do
        simulation.apply(create_village_command)
        simulation.apply(populate_command)
        expect(simulation.events.last).to be_a(PersonCreatedEvent)
        expect(simulation.events.last.person_name).to eq("Alice")
        expect(people_names_query).to eq(["Alice"])
      end

      it 'should create and populate two villages' do
        simulation.apply(create_village_command)
        simulation.apply(create_village_command)
        simulation.apply(populate_command)
        expect(people_names_query).to eq(["Alice", "Alice"])
      end
    end
  end
end
