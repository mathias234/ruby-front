# frozen_string_literal: true

# nodoc:
class PagedTable < Component
  def props
    %i[
      headers
      rows
    ]
  end

  def data
    pages = rows.each_slice(2).to_a

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

  def render
    table do
      tr do
        headers.each do |header|
          th do
            text header
          end
        end
      end

      current_rows.each do |row|
        tr do
          row.each do |col|
            td do
              text col
            end
          end
        end
      end
    end

    button class_name: 'm-1 p-2 bg-red-400', click!: @previous_page_handler do
      text 'Previous page'
    end

    button class_name: 'm-1 p-2 bg-red-400', click!: @next_page_handler do
      text 'Next page'
    end
  end
end
