# frozen_string_literal: true

# nodoc:
class Index < Component
  def data
    {
      h1_text: 'Click me',
      click_index: 0
    }
  end

  def setup
    @click_handler = lambda do |_ev|
      puts 'hi'
      self.click_index += 1
      self.h1_text = self.click_index.to_s
    end
  end

  def render
    h1 class_name: 'text-2xl', click!: @click_handler do
      text h1_text
    end
    component InputField
  end
end
