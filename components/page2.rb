# frozen_string_literal: true

# nodoc:
class Page2 < Component
  def data
    {
      rows: [[]]
    }
  end

  def render
    component(PagedTable, headers: %w[Test Test2 Test3 Test4])
  end
end
