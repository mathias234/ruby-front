# frozen_string_literal: true

# nodoc:
class IndexComponent < Component
  def props
    [
      :text_param
    ]
  end

  def data
    {
      text: 'Click me',
      click_index: 0
    }
  end

  def setup
    @click_handler = lambda do |_ev|
      self.click_index += 1
      self.text = "#{text_param} #{self.click_index}"
    end
  end

  def render(ctx)
    ctx.h1 class_name: 'text-2xl mt-2', on_click: @click_handler do |ctx|
      ctx.text(text)
    end
  end
end
