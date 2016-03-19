# metacosm

* [Homepage](https://rubygems.org/gems/metacosm)
* [Documentation](http://rubydoc.info/gems/metacosm/frames)
* [Email](mailto:jweissman1986 at gmail.com)

[![Code Climate GPA](https://codeclimate.com/github/deepcerulean/metacosm/badges/gpa.svg)](https://codeclimate.com/github/deepcerulean/metacosm)

## Description

Metacosm is an awesome microframework for building reactive systems.

## Goals

Enable quick prototyping of command-query separated architectures, and empower development of event-sourced systems.

## Background

One core concept is that we use commands to update "write-only" models, which trigger events that update "read-only" view models that are used by queries. 

Models only transform their state in response to commands, so their state can be reconstructed by replaying the stream of commands.

## Features

 - Distributed simulations using Redis 

## Examples

- [Game of Life](https://github.com/jweissman/gol), which implements Conway's game of life using metacosm and gosu
- [Socius](http://github.com/jweissman/socius), a civlike using the Redis integration to communicate with a game server running the sim

## Requirements

## Install

    $ gem install metacosm

## Synopsis

    $ metacosm

## Copyright

Copyright (c) 2016 Joseph Weissman

See {file:LICENSE.txt} for details.
