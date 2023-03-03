# frozen_string_literal: true

# nodoc:
class Index < Component
  def props
    [
      :text_param
    ]
  end

  def data
    {
      h1_text: 'Click me',
      click_index: 0
    }
  end

  def setup
    @click_handler = lambda do |_ev|
      self.click_index += 1
      self.h1_text = "#{text_param} #{self.click_index}"
    end
  end

  def render
    h1 class_name: 'text-2xl mt-2', click!: @click_handler do
      text(h1_text)
    end
    component InputField
  end
end
