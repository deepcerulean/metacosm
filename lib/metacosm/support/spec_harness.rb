RSpec::Matchers.define :trigger_event do |event|
  match do |command|
    # PassiveRecord.drop_all
    Simulation.current.clear!
    Simulation.current.apply(command)
    Simulation.current.events.include?(event)
  end

  failure_message do |command|
    "expected that #{command.inspect} would trigger #{event.inspect}! Actual events were: #{Simulation.current.events}"
  end
end

RSpec::Matchers.define :trigger_events do |*events|
  match do |command|
    # PassiveRecord.drop_all
    Simulation.current.clear!

    Simulation.current.apply(command)

    events.all? do |event|
      Simulation.current.events.include?(event)
    end
  end
end
