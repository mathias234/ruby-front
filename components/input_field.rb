class InputField < Component
  def data
    {
      current_text: 'Test'
    }
  end

  def setup
    @input_handler = lambda do |ev|
      pp ev[:target][:value]

      self.current_text = ev[:target][:value]
    end
  end

  def render
    input(value: current_text, class_name: 'border border-red-400', type: 'text', input!: @input_handler)
  end
end
