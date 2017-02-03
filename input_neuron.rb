require_relative 'base'
require_relative 'util'
#module Neuron
  class InputNeuron < Base
    attr_accessor :input
    def initialize(input: 0.0, enabled: true, name: '')
      super(enabled: enabled, name: name)
    end
    def output
      Util.sigmoid(@input)
    end
  end
#end
