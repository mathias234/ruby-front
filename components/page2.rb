# frozen_string_literal: true

# nodoc:
class Page2 < Component
  def data
    {
      rows: 1_000_000.times.map { |i| [i, i / 2, i / 3, i / 4] }
    }
  end

  def render
    component(PagedTable, headers: %w[Test Test2 Test3 Test4], rows: rows)
  end
end
