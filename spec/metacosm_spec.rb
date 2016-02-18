require 'spec_helper'

describe Model do
  subject(:model) { Model.create }
  describe "#id" do
    it 'should be retrievable by id' do
      expect(Model.find(model.id)).to eq(model)
    end
  end
end

describe "a simple simulation (fizzbuzz)" do
  subject(:simulation) { Simulation.new(model) }
  let(:model) { Counter.create }
  let(:last_event) { simulation.model_events.last }

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

        it { is_expected.to eq(1) } #"The counter is at 1") }
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
      let(:n) { 100 } # ops

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
        let(:m) { 50 }       # fibers
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
  subject(:simulation) { Simulation.new(world) }
  let(:world) { World.create }

  describe "#apply" do
    context 'create and populate villages' do
      let(:create_village_command) do
        CreateVillageCommand.new(world.id, "Oakville Ridge")
      end

      let(:village_names_query) do
        VillageNamesQuery.new.execute(world_id: world.id) 
      end

      it 'should make a village' do
        simulation.apply(create_village_command)
        expect(village_names_query).to eq(['Oakville Ridge'])
      end
    end
  end
end
