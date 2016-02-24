class Counter < Model
  def initialize
    @counter = 0
    super
  end

  def fizz!
    emit fizz
  end

  def buzz!
    emit buzz
  end

  def increment!(inc)
    @counter += inc
    emit(counter_incremented)
  end

  protected
  def fizz
    FizzEvent.create
  end

  def buzz
    BuzzEvent.create
  end

  def counter_incremented
    CounterIncrementedEvent.create(
      value: @counter,
      counter_id: @id
    )
  end
end

class CounterView < View
  attr_accessor :value, :counter_id
end

class CounterCreatedEvent < Event
  attr_accessor :counter_id #, :value
end

class CounterCreatedEventListener < EventListener
  def receive(counter_id:)
    CounterView.create(counter_id: counter_id, value: 0)
  end
end

class IncrementCounterCommand < Command
  attr_accessor :increment, :counter_id
end

class IncrementCounterCommandHandler
  def handle(increment:,counter_id:)
    counter = Counter.find(counter_id)
    counter.increment!(increment)
  end
end

class CounterIncrementedEvent < Event
  attr_accessor :value, :counter_id
end

class CounterIncrementedEventListener < EventListener
  def receive(value:,counter_id:)
    update_counter_view(counter_id, value)

    fizz_buzz!(counter_id, value)
    puts(value) unless fizz?(value) || buzz?(value)
  end

  def update_counter_view(counter_id, value)
    counter_view = CounterView.where(counter_id: counter_id).first_or_create
    counter_view.update value: value
  end

  private
  def fizz_buzz!(counter_id, n)
    fire(FizzCommand.create(counter_id: counter_id)) if fizz?(n)
    fire(BuzzCommand.create(counter_id: counter_id)) if buzz?(n)
  end

  def fizz?(n); n % 3 == 0 end
  def buzz?(n); n % 5 == 0 end
end

class FizzCommand < Command
  attr_accessor :counter_id
end

class FizzCommandHandler
  def handle(counter_id:)
    counter = Counter.find(counter_id)
    counter.fizz!
  end
end

class BuzzCommand < Command
  attr_accessor :counter_id
end

class BuzzCommandHandler
  def handle(counter_id:)
    counter = Counter.find(counter_id)
    counter.buzz!
  end
end

class FizzEvent < Event; end

class FizzEventListener < EventListener
  def receive
    puts "fizz"
  end
end

class BuzzEvent < Event; end

class BuzzEventListener < EventListener
  def receive
    puts "buzz"
  end
end

class CounterValueQuery
  def execute(counter_id:)
    counter = CounterView.find_by(counter_id: counter_id)
    counter.value
  end
end
