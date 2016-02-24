# metacosm

* [Homepage](https://rubygems.org/gems/metacosm)
* [Documentation](http://rubydoc.info/gems/metacosm/frames)
* [Email](mailto:jweissman1986 at gmail.com)

[![Code Climate GPA](https://codeclimate.com/github/deepcerulean/metacosm/badges/gpa.svg)](https://codeclimate.com/github/deepcerulean/metacosm)

## Description

Metacosm is an awesome microframework for building reactive systems.

The idea is to enable quick prototyping of command-query separated or event-sourced systems.

One core concept is that we use commands to update "write-only" models, 
which trigger events that update "read-only" view models that are used by queries. 

Models only transform their state in response to commands, so their state can be reconstructed by replaying the stream of commands.

## Features

 - One interesting feature here is a sort of mock in-memory AR component called `Registrable` that is used for internal tests (note: this has been extracted to [PassiveRecord](http://github.com/deepcerulean/passive_record))

## Examples

A Fizzbuzz implementation contrived enough to show off many of the features of the framework.

````ruby
  require 'metacosm'
  include Metacosm
  
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
    def update_value(new_value)
      @value = new_value
      self
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
  
  class FizzEvent < Event
  end
  
  class FizzEventListener < EventListener
    def receive
      puts "fizz"
    end
  end
  
  class BuzzEvent < Event
  end
  
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
  ````

  Given all this prelude we can run a fizzbuzz "simulation":

````ruby
  sim = Simulation.current
  counter_model = Counter.create
  counter_view = CounterView.find_by(counter_id: counter_model.id)
  
  counter_view.value # => 0

  increment_counter_command = IncrementCounterCommand.create(
    increment: 1, counter_id: counter_model.id
  )
  
  sim.apply(increment_counter_command)

  counter_view.value # => 1

  100.times { sim.apply(increment_counter_command) }

  sim.events.take(10)
  # => [CounterCreatedEvent (id: 1, counter_id: 1),
  #  CounterIncrementedEvent (id: 1, value: 1, counter_id: 1),
  #  CounterIncrementedEvent (id: 2, value: 2, counter_id: 1),
  #  CounterIncrementedEvent (id: 3, value: 3, counter_id: 1),
  #  FizzEvent (id: 1),
  #  CounterIncrementedEvent (id: 4, value: 4, counter_id: 1),
  #  CounterIncrementedEvent (id: 5, value: 5, counter_id: 1),
  #  BuzzEvent (id: 1),
  #  CounterIncrementedEvent (id: 6, value: 6, counter_id: 1)]
````

## Requirements

## Install

    $ gem install metacosm

## Synopsis

    $ metacosm

## Copyright

Copyright (c) 2016 Joseph Weissman

See {file:LICENSE.txt} for details.
