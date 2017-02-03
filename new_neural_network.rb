require 'matrix'
require_relative 'util'
class NewNeuralNetwork
  attr_accessor :neurons, :weights, :biases, :names
  def initialize(sizes)
    @weights = []
    @biases = []
    @neurons = []
    @names = {}
    num_layers = sizes.length
    (0..num_layers - 1).each do |i|
      @neurons << []
      unless i == 0
        @biases << []
        @weights << []
      end
      (0..sizes[i] - 1).each do |j|
        @neurons[-1] << 0.0
        unless i == 0
          @biases[-1] << Util.random_normal
          @weights[-1] << []
          (0..sizes[i - 1] - 1).each do |k|
            @weights[-1][j] << Util.random_normal
          end
        end
      end
    end
  end
  def to_hash
    hash = {}
    hash['weights'] = Marshal.load(Marshal.dump(@weights))
    hash['biases'] = Marshal.load(Marshal.dump(@biases))
    hash['neurons'] = Marshal.load(Marshal.dump(@neurons))
    hash['names'] = {}
    names.each do |key, value|
      hash['names'][key] = value
    end
    hash
  end
  def self.from_hash(hash)
    sizes = []
    hash['neurons'].each do |layer|
      sizes << layer.length
    end
    n = NewNeuralNetwork.new(sizes)
    (0..n.neurons.length - 1).each do |i|
      (0..n.neurons[i].length - 1).each do |j|
        n.neurons[i][j] = hash['neurons'][i][j]
      end
    end
    (0..n.weights.length - 1).each do |i|
      (0..n.weights[i].length - 1).each do |j|
        (0..n.neurons[i].length - 1).each do |k|
          n.weights[i][j][k] = hash['weights'][i][j][k]
        end
      end
    end
    hash['names'].each do |key, value|
      n.names[key] = value
    end
    n
  end
  def outputs
    @neurons.length > 0 ? @neurons[-1] : []
  end
  def inputs
    @neurons.length > 0 ? @neurons[0] : []
  end
  def feed_forward
    zs = []
    (1..@neurons.length - 1).each do |i|
      a = Matrix.rows(@weights[i - 1], false)
      b = Matrix.columns([@neurons[i - 1]])
      c = Matrix.columns([@biases[i - 1]])
      outputs = a * b + c
      zs << outputs
      (0..@neurons[i].length - 1).each do |j|
        @neurons[i][j] = Util.sigmoid(outputs[j, 0])
      end
    end
    outputs
  end
  def name_neuron(i, j, name)
    @names[name] = [i, j]
  end
  def [](name)
    @neurons[@names[name][0]][@names[name][1]]
  end
  def []=(name, value)
    @neurons[@names[name][0]][@names[name][1]] = value
  end
end
