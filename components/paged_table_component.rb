# frozen_string_literal: true

# nodoc:
class PagedTableComponent < Component
  def props
    %i[
      headers
      rows
    ]
  end

  def data
    pages = rows.each_slice(20).to_a

    {
      pages: pages,
      current_page: 0,
      current_rows: pages[0]
    }
  end

  def setup
    @next_page_handler = lambda do |_ev|
      self.current_page += 1

      self.current_page = pages.length - 1 if self.current_page >= pages.length

      self.current_rows = pages[self.current_page]
    end

    @previous_page_handler = lambda do |_ev|
      self.current_page -= 1

      self.current_page = 0 if self.current_page.negative?

      self.current_rows = pages[self.current_page]
    end
  end

  def render(ctx)
    ctx.table do |ctx|
      ctx.tr do |ctx|
        headers.each do |header|
          ctx.th do |ctx|
            ctx.text header
          end
        end
      end

      current_rows.each do |row|
        ctx.tr do |ctx|
          row.each do |col|
            ctx.td do |ctx|
              ctx.text col
            end
          end
        end
      end

      ctx.button class_name: 'm-1 p-2 bg-red-400', on_click: @previous_page_handler do |ctx|
        ctx.text 'Previous page'
      end

      ctx.button class_name: 'm-1 p-2 bg-red-400', on_click: @next_page_handler do |ctx|
        ctx.text 'Next page'
      end
    end
  end
end
