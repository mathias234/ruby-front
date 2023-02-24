# frozen_string_literal: true

# nodoc:
class Page2Component < Component
  def render(ctx)
    ctx.h1 class_name: 'text-2xl mt-2' do |ctx|
      ctx.text 'You are currently viewing Page 2'
    end

    ctx.component(PagedTableComponent, headers: %w[Test Test2 Test3], rows: 100.times.map { |i| [i, i / 2, i / 3] })
  end
end
