# frozen_string_literal: true

# nodoc:
class Home < Component
  def data
    {
      page: Index,
      pages: [
        { name: 'Index', component: Index },
        { name: 'Page 2', component: Page2 }
      ]
    }
  end

  def render
    div class_name: 'container mx-auto' do
      pages.each do |page|
        click_lambda = lambda do |_ev|
          self.page = page[:component]
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
