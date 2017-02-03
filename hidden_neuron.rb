require_relative 'base'
require_relative 'util'
#module Neuron
  class HiddenNeuron < Base
    attr_reader :output, :weights, :inputs
    attr_accessor :bias
    def initialize(bias: nil, enabled: true, name: '')
      super(enabled: enabled, name: name)
      @bias = bias.nil? ? Util.random_normal : bias
      @inputs = []
      @weights = []
      @output = 0.0
    end
    def [](i)
      @inputs[i].output * @weights[i]
    end
    def recalculate
      sum = 0.0
      (0..@inputs.length - 1).each do |i|
        if @inputs[i].enabled?
          sum += Util.sigmoid(@inputs[i].output) * @weights[i]
        end
      end
      @output = sum + @bias
    end
    def add_input(neuron, weight = nil)
      weight = Util.random_normal if
        weight.nil?
      @inputs << neuron
      @weights << weight
    end
    def <<(input)
      if input.is_a? Array
        add_input(input[0], input[1])
      else
        add_input(input)
      end
    end
  end
#end
