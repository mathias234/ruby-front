# frozen_string_literal: true

# nodoc:
class Page2 < Component
  def data
    {
      rows: [[]],
      some_model: ''
    }
  end

  def watch_some_model(changed)
    puts "Some model changed into #{changed}"
  end

  def render
    component(PagedTable, model: :some_model, headers: %w[Test Test2 Test3 Test4])
  end
end
