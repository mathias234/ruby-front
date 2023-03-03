# frozen_string_literal: true

# nodoc:
class Page2 < Component
  def data
    {
      rows: 1_000_000.times.map { |i| [i, i / 2, i / 3] }
    }
  end

  def render
    h1 class_name: 'text-2xl mt-2' do
      text 'You are currently viewing Page 2'
    end

    component(PagedTable, headers: %w[Test Test2 Test3], rows: rows)
  end
end
