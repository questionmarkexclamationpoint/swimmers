class Graph < JPanel
  def initialize(max_size = 1000)
    super(GridBagLayout.new)
    @hash = {}
    @max_size = max_size
  end
  def [](index)
    @hash[index]
  end
  def []=(index, value)
    if value.length > @max_size  
      @hash[index] = value[(value.length - @max_size)..@max_size - 1]
    else
      @hash[index] = value
    end
  end
  def push(index, value)
    @hash[index] ||= []
    @hash[index] << value
    @hash[index].delete_at(0)
    value
  end
  def paint_component(graphics)
    @hash.each do |k, v|
      @text_fields[k] = v[0]
    end
    super
    
  end
  def paintComponent(graphics)
    paint_component(graphics)
  end
  
  private
  
  def plot_panel
  
  end
  def initialize_grid
    @constraints = GridBagConstraints.new
    @constraints.fill = GridBagConstraints::HORIZONTAL
    @constraints.weightx = 1.0
    @constraints.weighty = 1.0
    @constraints.gridx = 0
    @constraints.gridy = 0
    @text_fields = {}
    @labels = {}
    @hash.each do |k, v|
      @constraints.gridy = 0
      @labels[k] = label = JLabel.new(k)
      add(label, @constraints)
      @constraints.grid_y += 1
      @labels[k] = field = JTextField.new
      field.set_text(v[0].to_s)
      field.set_editable(false)
      add(field, @constraints)
      @constraints.gridx += 1
    end
    @constraints.gridx = 0
    @constraints.gridy += 1
  end
end
