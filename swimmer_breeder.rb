require 'java'
require 'json'
require_relative 'swimmer'
java_import 'java.awt.geom.Line2D'
java_import 'java.awt.geom.Ellipse2D'
java_import 'javax.swing.JComponent'
java_import 'javax.swing.JPanel'
java_import 'javax.swing.JFrame'
java_import 'java.awt.Color'
java_import 'java.awt.Dimension'
java_import 'java.awt.event.WindowEvent'
java_import 'javax.swing.JOptionPane'

#module Swimmers
  class SwimmerBreeder
    attr_accessor :goal_x, :goal_y, :start_food, :max, :swimmers, :goal_size, :num_swimmers, :num_species, :species_index, :width, :height
    def initialize(num_swimmers: 10, width: 100, height: 100, start_food: 1000, num_species: 10)
      @width = width
      @height = height
      @goal_x = rand * width / 2 + width / 4
      @goal_y = rand * height / 2 + height / 4
      @goal_size = 25
      @swimmers = []
      @num_swimmers = num_swimmers
      @start_food = start_food
      @num_species = num_species
      @species_index = {}
      @max = {}
      (0..@num_species - 1).each do |i|
        s = Swimmer.new(color: Color.new(rand, rand, rand), start_food: @start_food,
                        x: rand * width, y: rand * height,
                        rotation: rand * 360, speed: rand * 10,
                        goal_x: @goal_x, goal_y: @goal_y, goal_size: @goal_size,
                        width: width, height: height)
        @max[s.species] = []
        @max[s.species] << s
      end
      max.each do |key, value|
        @swimmers << value[0]
      end
    end
    def paint(graphics)
      update
      graphics.set_color(Color::BLACK)
      graphics.fill_oval(@goal_x, @goal_y, @goal_size, @goal_size)
      @swimmers.each do |swimmer|
        swimmer.paint(graphics)
      end
    end
    def save(filename)
      File.open('saves/' + filename, 'w') do |f|
        f.puts JSON.pretty_generate(self.to_hash)
      end
    end
    def to_hash
      hash = {}
      hash['num_swimmers'] = @num_swimmers
      hash['num_species'] = @num_species
      hash['max'] = {}
      @max.each do |key, value|
        hash['max'][key] = []
        @max[key].each do |m|
          hash['max'][key] << m
        end
      end
      hash['goal_x'] = @goal_x
      hash['goal_y'] = @goal_y
      hash['goal_size'] = @goal_size
      hash['swimmers'] = []
      @swimmers.each do |s|
        hash['swimmers'] << s.to_hash
      end
      hash
    end
    def equal?(other_screen)
      false
    end
    def self.from_hash(hash)
      s = SwimmerScreen.new
      s.num_swimmers = hash['num_swimmers']
      s.num_species = hash['num_species']
      s.species_index = {}
      hash['species_index'].each do |key, value|
        s.species_index[key] = value
      end
      s.goal_x = hash['goal_x']
      s.goal_y = hash['goal_y']
      s.goal_size = hash['goal_size']
      s.swimmers = []
      hash['swimmers'].each do |i|
        s.swimmers << Swimmer.from_hash(i)
      end
      s.max = []
      hash['max'].each do |i|
        s.max << []
        i.each do |j|
          Swimmer.from_hash(j)
        end
      end
      s
    end
    def update
      update_swimmers
      if @swimmers.length < @num_swimmers
        repopulate
      end
    end
    
    def closest_pair(swimmers_x = nil, swimmers_y = nil)
      closest = nil
      pair = nil
      if swimmers_x.nil?
        swimmers_x = @swimmers.sort_by do |s|
          s.x
        end
      end
      if swimmers_y.nil?
        swimmers_y = @swimmers.sort_by do |s|
          s.y
        end
      end
      if (swimmers_x | swimmers_y).length <= 3
        s = swimmers_x | swimmers_y
        if s.length == 1
          closest = Float::INFINITY
          pair = [s[0], s[0]]
        elsif s.length == 2
          if s[0].equal? s[2]
            closest = Float::INFINITY
          else
            closest = Math.sqrt((s[0].y - s[1].y)**2 + (s[0].x - s[1].x)**2)
          end
          pair = [s[0], s[1]]
        else
          length_0 = Math.sqrt((s[1].x - s[0].x)**2 + (s[1].y - s[0].y)**2)
          length_1 = Math.sqrt((s[2].x - s[0].x)**2 + (s[2].y - s[0].y)**2)
          length_2 = Math.sqrt((s[2].x - s[1].x)**2 + (s[2].y - s[1].y)**2)
          if length_0 >= length_1 && length_0 >= length_2
            if s[0].equal? s[1]
              closest = Float::INFINITY
            else
              closest = length_0
            end
            pair = [s[0], s[1]]
          elsif length_1 >= length_0 && length_1 >= length_2
            if s[0].equal? s[2]
              closest = Float::INFINITY
            else
              closest = length_0
            end
            pair = [s[0], s[2]]
          else
            if s[1].equal? s[2]
              closest = Float::INFINITY
            else
              closest = length_0
            end
            pair = [s[1], s[2]]
          end
        end   
      else
        x_l = swimmers_x[0..swimmers_x.length / 2 - 1]
        x_r = swimmers_x[swimmers_x.length / 2..-1]
        x_m = swimmers_x[swimmers_x.length / 2].x 
        y_l = swimmers_y.select do |s|
          s.x < x_m
        end
        y_r = swimmers_y.select do |s|
          s.x >= x_m
        end
        d_l = nil
        d_r = nil
        pair_l = nil
        pair_r = nil
        threads = []
        pair_thread = Thread.new {d_l, pair_l = closest_pair(x_l, y_l)}
        d_r, pair_r = closest_pair(x_r, y_r)
        pair_thread.join
        d_min = d_r
        pair_min = pair_r
        if d_l < d_r
          d_min = d_l
          pair_min = pair_l
        end
        y_s = swimmers_y.select do |s|
          (x_m - s.x).abs < d_min
        end
        n_s = y_s.length
        closest = d_min
        pair = pair_min
        (0..n_s - 2).each do |i|
          j = i + 1
          (j..n_s - 1).each do |j|
            length = Math.sqrt((y_s[i].y - y_s[j].y)**2 + (y_s[i].x - y_s[j].x)**2).abs
            break unless length < d_min
            if length < closest
              closest = length
              pair = [y_s[j], y_s[i]]
            end
          end
        end
      end
      [closest, pair]
    end
    
    private
    
    def update_swimmers
      @swimmers.sort_by! do |s|
        s.goal_distance
      end
      threads = []
      found = false
      x = @swimmers.sort_by do |s|
        s.x
      end
      y = x.sort_by do |s|
        s.y
      end
      @swimmers.each do |swimmer|
        threads << Thread.new do
          closest = nil
          pair = nil
          pair_thread = Thread.new do 
            closest, pair = closest_pair(x, y)
          end
          if !found && swimmer.hit?
            u = Util.random_normal * @max[swimmer.species].length / 2
            u = [u.abs.floor, @max[swimmer.species].length - 1].min
            food = @swimmers.length > @num_swimmers * 5 ? 0 : 5
            s = swimmer.feed(@max[swimmer.species][u], food)
            unless @swimmers.length >= @num_swimmers * 5
              s.each do |i|
                @swimmers << i
              end
            end
            found = true
          elsif swimmer.food <= 0
            if swimmer.mother.nil?
              parent_fitness = 0.0
            else
              parent_fitness = (swimmer.mother.fitness + swimmer.father.fitness) / 2
            end
            if swimmer.fitness > parent_fitness + 5**(parent_fitness / 4)
              swimmer.mutate_name
              swimmer.species = swimmer.name
              @max[swimmer.species] = [swimmer]
              best = @max.values.sort_by! do |s|
                s[0].fitness
              end
              @max.delete(best[0][0].species)
            elsif swimmer.fitness > @max[swimmer.species][-1].fitness
              @max[swimmer.species] ||= [swimmer]
              max = @max[swimmer.species]
              if max.length < 10 && !(max.include? swimmer)
                max << swimmer
              elsif !max.include? swimmer
                max[-1] = swimmer
              end
            end
            @swimmers.delete(swimmer)
          end
          pair_thread.join
          if pair[0].hit?(pair[1].x, pair[1].y, pair[1].size, pair[1].size)
            if pair[0].eat?
              pair[0].feed(pair[0],pair[1].food * 0.1)
            elsif pair[1].eat?
              pair[1].feed(pair[1],pair[0].food * 0.1)
            end
          end
          pair[1].hearing = pair[0].speech
          pair[1].is_same_species = pair[0].species == pair[1].species ? 1.0 : 0.0
          pair[1].speaker_food = pair[0].food
          x -= [pair[0]]
          y -= [pair[0]]
        end
        swimmer.update
      end
      threads.each do |t|
        t.join
      end
      if found
        @goal_x = rand * @width
        @goal_y = rand * @height
        @swimmers.each do |swimmer|
          swimmer.goal_x = @goal_x + @goal_size
          swimmer.goal_y = @goal_y + @goal_size
          swimmer.goal_size = @goal_size
        end
      end
    end
    def repopulate
      @max.each do |key, value|
        value.sort_by! do |n|
          n.fitness
        end
        value.reverse!
      end
      best = @max.values.sort_by! do |m|
        m[0].fitness
      end
      best.reverse!
      if @best != best[0][0]
        puts
        puts "Record:"
        @best = best[0][0]
        @best.print
        puts @max.length
      end
      while @swimmers.length < @num_swimmers
        u = Util.random_normal * @max.length / 2
        i = [u.abs.floor, best.length - 1].min
        u = Util.random_normal * best[i].length / 4
        j = [u.abs.floor, best[i].length - 1].min
        u = Util.random_normal * best[i].length / 4
        k = [u.abs.floor, best[i].length - 1].min
        if (best[0][0].food_found == 0 && best[0][0].gen == 0) || (best[i][j].food_found == 0 && best[i][j].gen == 0)
          s = best[0][0].reproduce(best[i][j], 1.0)
          s.gen -=1
        elsif rand < 0.5
          s = best[0][0].reproduce
          s.gen -= 1
        else
          s = best[i][j].reproduce(best[i][k])
        end
        s.x = rand * @width
        s.y = rand * @height
        @swimmers << s
      end
    end
  end
#end
