class InputField < Component
  def data
    {
      current_text: 'Test'
    }
  end

  def render
    div do
      text current_text
    end

    input model: :current_text, class_name: 'border border-red-400', type: 'text'
  end
end
