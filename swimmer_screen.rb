require 'java'
require 'json'
require_relative 'swimmer'
require_relative 'swimmer_breeder'
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
    def initialize(num_swimmers: 10, width: 100, height: 100, start_food: 1000, num_species: 10)
      super()
      @swimmer_breeder = SwimmerBreeder.new(num_swimmers: num_swimmers, width: width, height: height, start_food: start_food, num_species: num_species)
      set_preferred_size(Dimension.new(width, height))
      @swimmer_breeder
    end
    def width=(w)
      @swimmer_breeder.width = w
      set_preferred_size(Dimension.new(w, @swimmer_breeder.height))
      w
    end
    def height=(h)
      @swimmer_breeder.height = h
      set_preferred_size(Dimension.new(@swimmer_breeder.w, h))
      h
    end
    def paint_component(graphics)
      super(graphics)
      @swimmer_breeder.paint(graphics)
    end
    def paintComponent(graphics)
      paint_component(graphics)
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
  s = SwimmerScreen.new(width: 1000, height: 1000, num_swimmers: 10, start_food: 2500, num_species: 10)
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
