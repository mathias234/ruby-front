# frozen_string_literal: true

# nodoc:
class PagedTable < Component
  def props
    %i[
      headers
    ]
  end

  def data
    {
      rows: [],
      pages: [],
      current_page: 0,
      current_rows: []
    }
  end

  def setup
    self.rows = 1_000_000.times.map { |i| [i, i / 2, i / 3, i / 4] }
    self.pages = rows.each_slice(20).to_a
    self.current_rows = pages[0]

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

  def watch_pages(_new_pages)
    emit input!: 'Yeet!!'
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

    button class_name: 'm-1 p-2 bg-red-400', click!: @previous_page_handler do
      text 'Previous page'
    end

    button class_name: 'm-1 p-2 bg-red-400', click!: @next_page_handler do
      text 'Next page'
    end
  end
end
