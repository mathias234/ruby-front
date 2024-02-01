# frozen_string_literal: true

require 'json'

# nodoc:
class Page2 < Component
  def data
    {
      rows: [['Loading...']],
      headers: ['Nothing']
    }
  end

  def setup
    fetch('test.txt') do |text|
      puts "Yeet #{text}"
    end

    fetch('https://swapi.dev/api/people/1/') do |json|
      JSON.parse("#{json}").each do |key, value|
        puts "#{key}: #{value}"
      end
    end

    set_timeout(timeout: 0) do
      self.headers = %w[Test Test2 Test3 Test4]
      self.rows = 1_000_000.times.map { |i| [i, i / 2, i / 3, i / 4] }
    end
  end

  def render
    component(PagedTable, headers: headers, rows: rows)
  end
end
