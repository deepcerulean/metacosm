require 'rspec'
require 'rspec/its'

require 'pry'
require 'ostruct'
require 'metacosm'
require 'metacosm/hstruct'

include Metacosm

require 'support/fizz_buzz'
require 'support/village'

class GivenWhenThen < Struct.new(:given_events,:when_command,:then_event_class)
  include RSpec::Matchers
  def when(command)
    @when_command = command
    self
  end

  # def expect_event_of_type(klass, with_attributes: {})
  #   @then_event_class = klass
  #   @then_events_attrs = with_attributes unless with_attributes.empty?
  #   verify!
  #   self
  # end

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

  def verify!
    PassiveRecord.drop_all
    Simulation.current.clear!

    # TODO maybe clean slate here? (zero out events and destroy all models?)
    self.given_events.each { |e| sim.receive(e) } if self.given_events

    sim.apply(@when_command) if @when_command

    expect(@then_event_class).to eq(sim.events.last.class) if @then_event_class

    expect(@then_events).to match_array(sim.events) if @then_events

    if @then_event_attrs
      @then_event_attrs.each do |k,v|
        expect(sim.events.last.send(k)).to eq(v)
      end
    end

    if @query
      expect(@query.execute).to eq(@expected_query_results)
    end

    self
  end

  def sim
    Simulation.current
  end
end

module Metacosm
  module SpecHelpers
    def given_no_activity
      GivenWhenThen.new
    end

    def given_events(events)
      GivenWhenThen.new(events)
    end
  end
end

RSpec.configure do |c|
  c.include Metacosm::SpecHelpers
end
