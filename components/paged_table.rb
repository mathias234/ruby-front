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
    {
      pages: [],
      current_page: 0,
      current_rows: []
    }
  end

  def setup
    recompute_pages
  end

  def watch_rows(_new_rows)
    recompute_pages
  end

  def recompute_pages
    self.pages = rows.each_slice(20).to_a
    self.current_rows = pages[0]
  end

  def next_page_handler(_event)
    self.current_page += 1

    self.current_page = pages.length - 1 if self.current_page >= pages.length

    self.current_rows = pages[self.current_page]
  end

  def previous_page_handler(_event)
    self.current_page -= 1

    self.current_page = 0 if self.current_page.negative?

    self.current_rows = pages[self.current_page]
  end

  def render
    table class_name: 'w-full' do
      thead do
        tr do
          headers.each do |header|
            th class_name: 'text-left p-2 border-b-2 border-gray-400' do
              text header
            end
          end
        end
      end

      tbody do
        current_rows.each do |row|
          tr do
            row.each do |col|
              td class_name: 'p-2 border-b-2 border-gray-400' do
                text col
              end
            end
          end
        end
      end
    end

    button class_name: 'm-1 p-2 bg-red-400', click!: :previous_page_handler do
      text 'Previous page'
    end

    button class_name: 'm-1 p-2 bg-red-400', click!: :next_page_handler do
      text 'Next page'
    end
  end
end
