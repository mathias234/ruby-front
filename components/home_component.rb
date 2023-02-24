# frozen_string_literal: true

# nodoc:
class HomeComponent < Component
  def data
    {
      page: 'page2'
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

  def render(ctx)
    ctx.div do |ctx|
      ctx.button class_name: 'm-1 p-2 bg-red-400', on_click: @set_page_index do |ctx|
        ctx.text('Go to index')
      end

      ctx.button class_name: 'm-1 p-2 bg-red-400', on_click: @set_page_page2 do |ctx|
        ctx.text('Go to page2')
      end

      render_page(ctx)
    end
  end

  private

  def render_page(ctx)
    puts page
    case page
    when 'index'
      ctx.component(IndexComponent, text_param: 'Hello world')
    when 'page2'
      ctx.component(Page2Component)
    end
  end
end
