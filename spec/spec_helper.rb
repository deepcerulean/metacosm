require 'rspec'
require 'rspec/its'

require 'pry'
require 'ostruct'
require 'metacosm'
require 'metacosm/support/test_harness'
require 'metacosm/support/spec_harness'

include Metacosm

require 'support/fizz_buzz'
require 'support/village'

RSpec.configure do |c|
  c.include Metacosm::TestHarness
end
