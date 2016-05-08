def hash_diff(h1,other)
  h1.dup.
    delete_if { |k, v| other[k] == v }.
    merge!(other.dup.delete_if { |k, v| h1.has_key?(k) })
end

RSpec::Matchers.define :trigger_event do |event|
  match do |command|
    # PassiveRecord.drop_all
    Metacosm::Simulation.current.clear!
    Metacosm::Simulation.current.apply(command)
    Metacosm::Simulation.current.events.include?(event)
  end

  failure_message do |command|
    actual_events = Metacosm::Simulation.current.events
    if actual_events.count == 1 # give detailed diff..
      actual_event = actual_events.first 
      "expected that #{command.inspect} would trigger #{event.inspect}!\n" +
        "Actual event was #{actual_event.inspect}\n" +
        "Diff: \n" +
        hash_diff(actual_event.attrs,event.attrs).inspect
    else
      "expected that #{command.inspect} would trigger #{event.inspect}!\n" +
        "Actual events were:\n" +
        " - #{actual_events.map(&:inspect).join("\n  - ")}"
    end
  end
end

RSpec::Matchers.define :trigger_events do |*events|
  match do |command|
    # PassiveRecord.drop_all
    Metacosm::Simulation.current.clear!

    Metacosm::Simulation.current.apply(command)

    events.all? do |event|
      Metacosm::Simulation.current.events.include?(event)
    end
  end
end
