module Metacosm
  module TestHarness
    class GivenWhenThen < Struct.new(:given_events,:when_command,:then_event_class)
      include RSpec::Matchers

      def when(*commands)
        @when_commands ||= []
        commands.each do |command|
          @when_commands.push command
        end
        self
      end

      def expect_events(evts)
        @then_events = evts
        verify!
        self
      end

      def expect_query(query, to_find:)
        @query = query
        @expected_query_results = to_find
        verify!
        self
      end

      protected

      def verify!
        clean_slate!
        receive_events!
        fire_commands!

        validate_events!
        validate_query!

        self
      end

      private

      def clean_slate!
        PassiveRecord.drop_all
        Simulation.current.clear!
        self
      end

      def receive_events!
        unless self.given_events.nil?
          self.given_events.each do |evt| 
            sim.receive(evt, record: false)
          end
        end
        self
      end

      def fire_commands!
        unless @when_commands.nil?
          @when_commands.each do |cmd|
            sim.apply(cmd)
          end
        end
        self
      end

      def validate_events!
        if @then_event_class
          expect(@then_event_class).to eq(sim.events.last.class) 
        end

        if @then_events
          expect(@then_events).to match_array(sim.events) 
        end

        if @then_event_attrs
          @then_event_attrs.each do |k,v|
            expect(sim.events.last.send(k)).to eq(v)
          end
        end

        self
      end

      def validate_query!
        if @query
          expect(@query.execute).to eq(@expected_query_results)
        end
        self
      end

      def sim
        @sim ||= Simulation.current
      end
    end

    def given_no_activity
      GivenWhenThen.new
    end

    def given_events(events)
      GivenWhenThen.new(events)
    end
  end
end
