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
    FizzEvent.create(value: @counter, counter_id: @id)
  end

  def buzz
    BuzzEvent.create(value: @counter, counter_id: @id)
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
  def update_value(new_value)
    @value = new_value
    self
  end
end

class IncrementCounterCommand < Struct.new(:increment, :counter_id)
end

class IncrementCounterCommandHandler
  def handle(command)
    counter = Counter.find_by(command.counter_id)
    counter.increment!(command.increment)
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
    counter_view.value = value
  end

  private
  def fizz_buzz!(counter_id, n)
    fire(FizzCommand.new(counter_id, n)) if fizz?(n)
    fire(BuzzCommand.new(counter_id, n)) if buzz?(n)
  end

  def fizz?(n); n % 3 == 0 end
  def buzz?(n); n % 5 == 0 end
end

class FizzCommand < Struct.new(:counter_id, :value); end
class FizzCommandHandler
  def handle(command)
    counter = Counter.find_by(command.counter_id)
    counter.fizz!
  end
end

class BuzzCommand < Struct.new(:counter_id, :value); end
class BuzzCommandHandler
  def handle(command)
    counter = Counter.find_by(command.counter_id)
    counter.buzz!
  end
end

class FizzEvent < Event
  attr_accessor :value, :counter_id
end

class FizzEventListener < EventListener
  def receive(event)
    puts "fizz"
  end
end

class BuzzEvent < Event
  attr_accessor :value, :counter_id
end

class BuzzEventListener < EventListener
  def receive(event)
    puts "buzz"
  end
end

class CounterValueQuery
  def execute(counter_id:)
    counter = CounterView.find_by(counter_id: counter_id)
    counter.value
  end
end
