require_relative 'input_neuron'
require_relative 'hidden_neuron'
class NeuralNetwork
  attr_reader :hidden_layers, :inputs
  def initialize
    @hidden_layers = [[]]
    @inputs = []
  end
  def add_layer(layer)
    new_layer = []
    iterations = layer.is_a?(Array) ? layer.length : layer
    (0..iterations - 1).each do |i|
      neuron = nil
      if layer.is_a? Array
        neuron = layer[i]
      else
        neuron = HiddenNeuron.new
      end
      if @hidden_layers.length == 0
        @inputs.each do |input|
          neuron << input
        end
      else
        @hidden_layers[-1].each do |input|
          neuron << input
        end
      end
      new_layer << neuron
    end
    @hidden_layers << new_layer
  end
  def add_input(neuron)
    @inputs << neuron
    unless @hidden_layers.length == 0
      @hidden_layers[0].each do |output|
        output << neuron
      end
    end
    @inputs
  end
  def add_output(neuron)
    @hidden_layers[-1] << neuron
    if @hidden_layers.length == 1
      @inputs.each do |input|
        neuron << input
      end
    else
      @hidden_layers[-2].each do |input|
        neuron << input
      end
    end
    @hidden_layers[-1]
  end
  def outputs
    if @hidden_layers.length > 0
      @hidden_layers[-1]
    else
      []
    end
  end
  def feed_forward
    neurons = @hidden_layers.flatten
    arr = []
    neurons.each do |neuron|
      hash = {}
      hash['neuron'] = neuron
      hash['num_inputs'] = 0
      neuron.inputs.each do |input|
        if input.is_a? HiddenNeuron
          hash['num_inputs'] += 1
        end
      end
      arr << hash
    end
    arr.sort_by do |hash|
      hash['num_inputs']
    end
    until arr.empty?
      arr[-1]['neuron'].recalculate
      arr.each do |hash|
        if hash['neuron'].inputs.include? arr[-1]['neuron']
          hash['num_inputs'] -= 1
        end
      end
      arr.pop(1)
      arr.sort_by do |hash|
        hash['num_inputs']
      end
    end
  end
end
