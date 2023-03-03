# frozen_string_literal: true

# nodoc:
class Home < Component
  def data
    {
      page: 'index'
    }
  end

  def setup
    @set_page_index = lambda do |_ev|
      self.page = 'index'
    end

    @set_page_page2 = lambda do |_ev|
      self.page = 'page2'
    end
  end

  def render
    div do
      button class_name: 'm-1 p-2 bg-red-400', click!: @set_page_index do
        text('Go to index')
      end

      button class_name: 'm-1 p-2 bg-red-400', click!: @set_page_page2 do
        text('Go to page2')
      end

      render_page
    end
  end

  private

  def render_page
    puts page
    case page
    when 'index'
      component(Index, text_param: 'Hello world')
    when 'page2'
      component(Page2)
    end
  end
end
