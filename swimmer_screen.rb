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
  class SwimmerScreen < JPanel
    attr_reader :width, :height
    attr_accessor :goal_x, :goal_y, :start_food, :max, :swimmers, :goal_size, :num_swimmers, :num_species
    def initialize(num_swimmers: 10, width: 100, height: 100, start_food: 1000, num_species: 10)
      super()
      @width = width
      @height = height
      set_preferred_size(Dimension.new(width, height))
      @goal_x = rand * width / 2 + width / 4
      @goal_y = rand * height / 2 + height / 4
      @goal_size = 25
      @swimmers = []
      @num_swimmers = num_swimmers
      @start_food = start_food
      @num_species = num_species
      @max = []
      (0..@num_species - 1).each do |i|
        @max << []
        @max[-1] << Swimmer.new(color: Color.new(rand, rand, rand), species: i, start_food: @start_food,
                                 x: rand * width, y: rand * height,
                                 rotation: rand * 360, speed: rand * 10,
                                 goal_x: @goal_x, goal_y: @goal_y,
                                 width: width, height: height)
      end
      (0..num_swimmers - 1).each do |i|
        @swimmers << @max[i][0]
      end
    end
    def width=(w)
      @width = w
      set_preferred_size(Dimension.new(@width, @height))
      @width
    end
    def height=(h)
      @height = h
      set_preferred_size(Dimension.new(@width, @height))
      @height
    end
    def paint_component(graphics)
      super(graphics)
      update
      graphics.set_color(Color::BLACK)
      graphics.fill_oval(@goal_x, @goal_y, @goal_size, @goal_size)
      @swimmers.each do |swimmer|
        paint_swimmer(swimmer, graphics)
      end
    end
    def paintComponent(graphics)
      paint_component(graphics)
    end
    def save(filename)
      File.open('saves/' + filename, 'w') do |f|
        f.puts JSON.pretty_generate(self.to_hash)
      end
    end
    def to_hash
      @max.each do |m|
        m.sort_by! do |n|
          n.fitness
        end
        m.reverse!
      end
      @max.sort_by! do |m|
        m[0].species
      end
      hash = {}
      hash['num_swimmers'] = @num_swimmers
      hash['num_species'] = @num_species
      hash['goal_x'] = @goal_x
      hash['goal_y'] = @goal_y
      hash['goal_size'] = @goal_size
      hash['swimmers'] = []
      @swimmers.each do |s|
        hash['swimmers'] << s.to_hash
      end
      hash['max'] = []
      @max.each do |m|
        hash['max'] << []
        m.each do |i|
          hash['max'][-1] << i.to_hash
        end
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
    
    private
    
    def eat_food(swimmer, num_children = 5)
      swimmer.food += @start_food
      swimmer.food_found += 1
      @goal_x = rand * get_width / 2 + get_width / 4
      @goal_y = rand * get_height / 2 + get_width / 4
      unless @swimmers.length >= @num_swimmers * 5
        (0..num_children - 1).each do |i|
          @swimmers << swimmer.reproduce(swimmer)
        end
      end
      swimmer
    end
    def update
      #puts "#{@swimmers[0].x}, #{@swimmers[0].y}"
      #puts @swimmers[0].rotation
      #puts @swimmers[0].brain['goal_rotation']
      @swimmers.sort_by! do |s|
        s.goal_distance
      end
      @swimmers.each do |swimmer|
        if hit_goal(swimmer) 
          u = Util.random_normal * @max[swimmer.species].length / 2
          u = [u.abs.floor, @max[swimmer.species].length - 1].max
          s = swimmer.feed(@max[swimmer.species][u])
          unless @swimmers.length >= @num_swimmers * 5
            s.each do |i|
              @swimmers << i
            end
          end
          @goal_x = rand * get_width / 2 + get_width / 4
          @goal_y = rand * get_height / 2 + get_width / 4
          @swimmers.each do |swimmer|
            swimmer.goal_x = @goal_x + @goal_size / 2.0
            swimmer.goal_y = @goal_y + @goal_size / 2.0
            swimmer.hearing = @swimmers[0].speech
            swimmer.is_same_species = swimmer.species == @swimmers[0].is_same_species
          end
        elsif swimmer.food <= 0
          if swimmer.fitness > @max[swimmer.species][-1].fitness
            if @max[swimmer.species].length < 10
              @max[swimmer.species] << swimmer
            else
              @max[swimmer.species][-1] = swimmer
            end
            puts 'Good:'
            puts "  Species #{swimmer.species},"
            puts "  Fitness #{swimmer.fitness},"
            puts "  Food #{swimmer.food_found},"
            puts "  Gen #{swimmer.gen}"
          end
          @swimmers.delete(swimmer)
        end
        swimmer.hearing = @swimmers[0].speech
        swimmer.is_same_species = swimmer.species == @swimmers[0].is_same_species
        swimmer.update
      end
      first = true
      while @swimmers.length < @num_swimmers
        u = Util.random_normal * @max.length / 2
        i = [u.abs.floor, @max.length - 1].min
        @max.each do |m|
          m.sort_by! do |n|
            n.fitness
          end
          m.reverse!
        end
        @max.sort_by! do |m|
          m[0].fitness
        end
        @max.reverse!
        puts "#{@best != @max[0][0] ? 'New ' : ''}Record:"
        @best = @max[0][0]
        puts "  Species #{@best.species},"
        puts "  Fitness #{@best.fitness},"
        puts "  Food #{@best.food_found},"
        puts "  Gen #{@best.gen}"
        u = Util.random_normal * @max[i].length / 4
        j = [u.abs.floor, @max[i].length - 1].min
        u = Util.random_normal * @max[i].length / 4
        k = [u.abs.floor, @max[i].length - 1].min
        s = @max[i][j].reproduce(@max[i][k])
        @max.sort_by! do |m|
          m[0].species
        end
        s.x = rand * get_width
        s.y = rand * get_height
        s.gen -= 1
        @swimmers << s
      end
    end
    def paint_swimmer(swimmer, graphics)
      graphics.set_color(swimmer.color)
      max = [swimmer.delta_x, swimmer.delta_y].max
      max = -10.0/max
      line_length = swimmer.speed.abs + swimmer.size / 2
      line_x = swimmer.x + swimmer.size / 2
      line_y = swimmer.y + swimmer.size / 2
      line_right = Math.cos(-swimmer.rotation * 2 * Math::PI / 360) * line_length
      line_up = Math.sin(-swimmer.rotation * 2 * Math::PI / 360) * line_length
      if swimmer.speed < 0
        line_right *= -1
        line_up *= -1
      end
      graphics.draw_line(line_x, line_y, swimmer.x + line_right, swimmer.y + line_right)
      graphics.fill_oval(swimmer.x, swimmer.y, swimmer.size, swimmer.size)
      color = Color.new(Color.hs_bto_rgb(swimmer.speech, 1.0, 1.0)) #this jruby function is improperly named...
      graphics.set_color(color)
      graphics.fill_oval(swimmer.x + swimmer.size / 4, swimmer.y + swimmer.size / 4, swimmer.size / 2, swimmer.size / 2)
    end
    def hit_goal(swimmer)
      g = Ellipse2D::Double.new(@goal_x, @goal_y, @goal_size, @goal_size)
      s = Ellipse2D::Double.new(swimmer.x, swimmer.y, swimmer.size, swimmer.size)
      g.intersects(s.getBounds2D)
    end
  end
#end

def every_so_many_seconds(seconds)
  last_tick = Time.now
  loop do
    sleep 0.001
    if Time.now - last_tick >= seconds
      last_tick += seconds
      yield
    end
  end
end
frame = JFrame.new('test')
frame.set_default_close_operation(JFrame::EXIT_ON_CLOSE)
frame.set_size(1000, 1000)
filename = nil
if filename.nil?
  s = SwimmerScreen.new(width: 1000, height: 1000, num_swimmers: 2, start_food: 2500, num_species: 10)
else
  hash = JSON.parse(File.read(filename))
  s = SwimmerScreen.from_hash(hash)
end
frame.get_content_pane.add(s)
frame.pack
frame.set_resizable(false)
frame.add_window_listener do |e|
  if e.get_id == WindowEvent::WINDOW_CLOSING
    filename = 'saves/' + JOptionPane.show_input_dialog("Filename: ")
    s.save(filename)
    frame.dispose
  end
end
frame.set_visible(true)
while true do
  s.repaint
end
