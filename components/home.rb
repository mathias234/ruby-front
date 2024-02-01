# frozen_string_literal: true

# nodoc:
class Home < Component
  def data
    {
      page: Index,
      pages: [
        { name: 'Index', component: Index },
        { name: 'Page 2', component: Page2 },
        { name: 'Star Wars characters', component: StarWarsCharacters }
      ]
    }
  end

  def setup
    page_param = search_params.get('page')
    return unless page_param != JS::Null

    page_param = page_param.to_s

    page = pages.find { |page| page[:name] == page_param }
    return unless page

    self.page = page[:component]
  end

  def render
    div class_name: 'container mx-auto' do
      pages.each do |page|
        click_lambda = lambda do |_ev|
          self.page = page[:component]
          set_search_param('page', page[:name])
        end

        button class_name: 'p-2 my-2 mr-2 shadow-md border-2 border-gray-400 rounded', click!: click_lambda do
          text page[:name]
        end
      end
    end

    render_page
  end

  private

  def render_page
    div class_name: 'container mx-auto p-5 shadow-md border-2 border-gray-400 rounded' do
      component page
    end
  end
end
