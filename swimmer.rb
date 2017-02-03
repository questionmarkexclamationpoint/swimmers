require_relative 'neural_network'
require_relative 'new_neural_network'
java_import 'java.awt.Color'
#module Swimmers
  class Swimmer
    attr_accessor :color, 
                  :size, 
                  :x, 
                  :y, 
                  :goal_x, 
                  :goal_y, 
                  :height, 
                  :width, 
                  :speed, 
                  :rotation, 
                  :food, 
                  :gen, 
                  :food_found,
                  :brain,
                  :fitness,
                  :species,
                  :min_distance,
                  :start_food,
                  :mutation_chance,
                  :hearing,
                  :is_same_species,
                  :name
    attr_reader :brain
    def initialize(color: Color::WHITE, size: 10, species: '', start_food: 1000,
                   x: 0.0, y: 0.0, speed: 0.0, rotation: 0.0, 
                   goal_x: 0.0, goal_y: 0.0, 
                   width: 0.0, height: 0.0,
                   name: nil)
      @color = color
      @size = size
      @x = x
      @y = y
      @goal_x = goal_x
      @goal_y = goal_y
      @height = height
      @width = width
      @speed = speed
      @rotation = rotation
      @brain = initialize_brain
      @gen = 0
      @start_food = start_food
      @food = @start_food
      @food_found = 0
      @min_distance = goal_distance
      @fitness = 0.0
      @fitness = fitness_function
      @species = species
      @mutation_chance = 0.1
      @hearing = 0.0
      @is_same_species = false
      @name = name ||= @species
    end
    def to_hash
      hash = {}
      rgb = []
      rgb << @color.get_red << @color.get_green << @color.get_blue
      hash['color']           = rgb
      hash['size']            = @size
      hash['x']               = @x
      hash['y']               = @y
      hash['goal_y']          = @goal_y
      hash['height']          = @height
      hash['width']           = @width
      hash['speed']           = @speed
      hash['rotation']        = @rotation
      hash['brain']           = @brain.to_hash
      hash['gen']             = @gen
      hash['start_food']      = @start_food
      hash['food']            = @food
      hash['food_found']      = @food_found
      hash['min_distance']    = @min_distance
      hash['fitness']         = @fitness
      hash['species']         = @species
      hash['mutation_chance'] = @mutation_chance
      hash['hearing']         = @hearing
      hash['is_same_species'] = @is_same_species
      hash['name']            = @name
      hash
    end
    def self.from_hash(hash)
      s                 = Swimmer.new
      rgb               = hash['color']
      s.color           = Color.new(rgb[0], rgb[1], rgb[2])
      s.size            = hash['size']
      s.x               = hash['x']
      s.y               = hash['y']
      s.goal_y          = hash['goal_y']
      s.height          = hash['goal_height']
      s.width           = hash['goal_width']
      s.speed           = hash['speed']
      s.rotation        = hash['rotation']
      s.brain           = NewNeuralNetwork.from_hash(hash['brain'])
      s.gen             = hash['gen']
      s.start_food      = hash['start_food']
      s.food            = hash['food']
      s.food_found      = hash['food_found']
      s.min_distance    = hash['min_distance']
      s.fitness         = hash['fitness']
      s.species         = hash['species']
      s.mutation_chance = hash['mutation_chance']
      s.hearing         = hash['hearing']
      s.is_same_species = hash['species']
      s.name            = hash['name']
      s
    end
    def set_dna(dna)
      @color = dna['color']
      @size = dna['size']
      @brain = dna_to_brain(dna['network'])
    end
    def delta_x
      @speed * Math.sin(@rotation * 2 * Math::PI / 360)
    end
    def delta_y
      @speed * Math.cos(@rotation * 2 * Math::PI / 360)
    end
    def mutate(chance = nil)
      chance ||= @mutation_chance
      @mutate_chance = rand * 0.1 if
        chance < rand
      mutate_color(chance)
      mutate_brain(chance)
      mutate_name(chance)
    end
    def acceleration
      @brain['delta_s'] - 0.5
    end
    def delta_rotation
      @brain['delta_r'] - 0.5
    end
    def speech
      @brain['speech'] - 0.5
    end
    def goal_distance
      Math.sqrt((@y - @goal_y)**2 + (@x - @goal_x)**2)
    end
    def reproduce(partner = nil, mutate_chance = nil)
      partner ||= self
      mutate_chance ||= @mutate_chance
      child = Swimmer.new
      child.color = @color
      child.size = @size
      child.x = @x + (rand - 0.5) * 20
      child.y = @y + (rand - 0.5) * 20
      child.goal_x = @goal_x
      child.goal_y = @goal_y
      (0..@brain.weights.length - 1).each do |i|
        (0..@brain.weights[i].length - 1).each do |j|
          if rand < 0.5
            child.brain.biases[i][j] = @brain.biases[i][j]
          else
            child.brain.biases[i][j] = partner.brain.biases[i][j]
          end
          (0..@brain.weights[i][j].length - 1).each do |k|
            if rand < 0.5
              child.brain.weights[i][j][k] = @brain.weights[i][j][k]
            else
              child.brain.weights[i][j][k] = partner.brain.weights[i][j][k]
            end
          end
        end
      end
      child.width = @width
      child.height = @height
      child.food = @start_food
      child.fitness = 0.0
      child.gen = [@gen, partner.gen].min + 1
      child.species = @species
      child.update_inputs
      child.rotation = rand * 360
      child.speed = @speed
      child.min_distance = @min_distance
      child.mutate(mutate_chance)
      child
    end
    def update
      update_inputs
      brain.feed_forward
      @speed = [[@speed + acceleration, 1].min, -1].max
      @rotation += delta_rotation * 10
      @rotation %= 360
      @x += delta_x
      @y += delta_y
      @food -= @speed.abs
      @fitness = fitness_function
    end
    def feed(partner, num_children = 5)
      @food += @start_food
      @food_found += 1
      children = []
      (0..num_children - 1).each do |i|
        children << reproduce(partner)
      end
      children
    end
    def update_inputs
      @brain['random'] = rand
      @brain['rotation'] = @rotation / 360.0
      @brain['goal_rotation'] = goal_theta / 360.0
      @brain['x'] = @x / @width
      @brain['y'] = @y / @height
      @brain['goal_x'] = @goal_x / @width
      @brain['goal_y'] = @goal_y / @height
      @brain['hearing'] = @hearing
      @brain['is_same_species'] = @is_same_species ? 1.0 : 0.0
    end
    def diagonal
      Math.sqrt(@width**2 + @height**2)
    end
    
    private
    
    def fitness_function
      @min_distance = [goal_distance, @min_distance].min
      @fitness + (@food_found + (0.1 * @gen) - @min_distance / diagonal) / @start_food
    end
    def initialize_brain
      @brain = NewNeuralNetwork.new([9,20,3,1])
      @brain.name_neuron(0, 0, 'rotation')
      @brain.name_neuron(0, 1, 'goal_rotation')
      @brain.name_neuron(0, 2, 'x')
      @brain.name_neuron(0, 3, 'y')
      @brain.name_neuron(0, 4, 'goal_x')
      @brain.name_neuron(0, 5, 'goal_y')
      @brain.name_neuron(0, 6, 'random')
      @brain.name_neuron(0, 7, 'hearing')
      @brain.name_neuron(0, 8, 'is_same_species')
      
      @brain.name_neuron(-2, 0, 'delta_s')
      @brain.name_neuron(-2, 1, 'delta_r')
      @brain.name_neuron(-3, 0, 'speech')
      
      update_inputs
      
      @brain
    end
    def random_mutator(can_be_negative = true)
      i = rand / 2.0 + 0.75
      i *= -1 if
        rand < 0.5 && can_be_negative
      i
    end
    def mutate_color(chance = 0.01)
      rgb = []
      rgb << @color.get_red << @color.get_green << @color.get_blue
      (0..rgb.length - 1).each do |i|
        rgb[i] = (rand * 255).to_i if
         rand < chance
      end
      @color = Color.new(rgb[0], rgb[1], rgb[2])
    end
    def mutate_brain(chance = 0.01)
      (0..@brain.weights.length - 1).each do |i|
        (0..@brain.weights[i].length - 1).each do |j|
          @brain.biases[i][j] = Util.random_normal if
            rand < chance
          (0..@brain.weights[i][j].length - 1).each do |k|
            @brain.weights[i][j][k] = Util.random_normal if
              rand < chance
          end
        end
      end
    end
    def mutate_name(chance = 0.01)
    
    end
    def goal_theta
      x = (@x - @goal_x)
      y = (@y - @goal_y)
      Math.tan(x/y) * 360 / (2 * Math::PI)
    end
  end
#end
