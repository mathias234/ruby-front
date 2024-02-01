# frozen_string_literal: true

require 'json'

# nodoc:
class StarWarsCharacters < Component
  def data
    {
      rows: [['Loading']],
      headers: ['Name', 'Height', 'Mass', 'Hair Color', 'Skin Color', 'Eye Color', 'Birth Year', 'Gender']
    }
  end

  def setup
    fetch('https://swapi.dev/api/people/') do |json|
      result = JSON.parse(json.to_s)['results']
      self.rows = result.map do |character|
        character.values[0..7].map(&:to_s)
      end
    end
  end

  def render
    component(PagedTable, headers: headers, rows: rows) do
    end
  end
end
