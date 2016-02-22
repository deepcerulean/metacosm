# metacosm

* [Homepage](https://rubygems.org/gems/metacosm)
* [Documentation](http://rubydoc.info/gems/metacosm/frames)
* [Email](mailto:jweissman1986 at gmail.com)

[![Code Climate GPA](https://codeclimate.com/github/deepcerulean/metacosm/badges/gpa.svg)](https://codeclimate.com/github/deepcerulean/metacosm)

## Description

Metacosm is an awesome microframework for building reactive systems.

The idea is to enable quick prototyping of command-query separated or event-sourced systems.

One core concept is that we use commands to update "write-only" models, which trigger events that update "read-only" view models that are used by queries. Only models can trasnform their state, and they only transform their state in response to commands -- so that their state can be reconstructed by replaying the stream of commands that brought them into their current state.

We separate reading and writing in order to optimize and scale the different sides differently. They could be using totally different technologies -- one optimized for quick distributed writes, the other optimized for fast querying/view-rendering.

There is a reactive Fizz Buzz implementation in `spec/support/fizz_buzz.rb` that might be illustrative...

## Features

 - One interesting feature here is a sort of mock in-memory AR component called `Registrable` that is used for internal tests (note: this has been extracted to [PassiveRecord](http://github.com/deepcerulean/passive_record))

## Examples

    require 'metacosm'

## Requirements

## Install

    $ gem install metacosm

## Synopsis

    $ metacosm

## Copyright

Copyright (c) 2016 Joseph Weissman

See {file:LICENSE.txt} for details.
