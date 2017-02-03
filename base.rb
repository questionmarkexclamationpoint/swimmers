#module Neuron
  class Base
    attr_reader :outputs
    attr_accessor :enabled, :name
    def initialize(enabled: true, name: '')
      @name = name
      @enabled = enabled
    end
    def fired?
      output >= 0.5
    end
    def output
      0.0
    end
    def enabled?
      @enabled
    end
  end
#end
