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
    FizzEvent.new(@counter, @id)
  end

  def buzz
    BuzzEvent.new(@counter, @id)
  end

  def counter_incremented
    CounterIncrementedEvent.new(@counter, @id)
  end
end

class CounterView < View
  attr_reader :value, :counter_id

  def initialize(counter_id, value)
    @counter_id = counter_id
    @value = value
  end

  def update_value(new_value)
    @value = new_value
    self
  end
end

class IncrementCounterCommand < Struct.new(:increment, :counter_id)
end

class IncrementCounterCommandHandler
  def handle(command)
    counter = Counter.lookup(command.counter_id)
    counter.increment!(command.increment)
  end
end

class CounterIncrementedEvent < Struct.new(:counter_value, :counter_id); end

class CounterIncrementedEventListener < EventListener
  def receive(event)
    counter_id, value = event.counter_id, event.counter_value
    create_or_update_counter(counter_id, value)

    fizz_buzz!(counter_id, value)
    puts(value) unless fizz?(value) || buzz?(value)
  end

  protected
  def create_or_update_counter(counter_id, value)
    if (counter=CounterView.lookup(counter_id))
      counter.update_value(value)
    else
      CounterView.create(counter_id, value)
    end
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
    counter = Counter.lookup(command.counter_id)
    counter.fizz!
  end
end

class BuzzCommand < Struct.new(:counter_id, :value); end
class BuzzCommandHandler
  def handle(command)
    counter = Counter.lookup(command.counter_id)
    counter.buzz!
  end
end

class FizzEvent < Struct.new(:value, :counter_id); end
class FizzEventListener < EventListener
  def receive(event)
    puts "fizz"
  end
end

class BuzzEvent < Struct.new(:value, :counter_id); end
class BuzzEventListener < EventListener
  def receive(event)
    puts "buzz"
  end
end

class CounterValueQuery
  def execute(counter_id:)
    counter = CounterView.lookup(counter_id)
    counter.value
  end
end