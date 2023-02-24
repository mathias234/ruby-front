# frozen_string_literal: true

require 'js'

# nodoc:
class Element
  attr_accessor :attributes, :children

  def initialize(**attributes)
    @children = attributes[:children]
    @attributes = attributes
  end

  def render_to_html
    element = JS.global[:document].createElement(element_name)

    assign_attributes(element)

    @children.each do |child_element|
      element.appendChild(child_element.render_to_html)
    end

    register_events(element)

    element
  end

  def assign_attributes(element)
    element[:className] = attributes[:class_name] if attributes[:class_name]
    element[:id] = attributes[:id] if attributes[:id]
  end

  def register_events(element)
    on_click = attributes[:on_click]

    return unless on_click

    element.addEventListener('click') do |event|
      on_click.call(event)
    end
  end

  def element_name
    ''
  end
end

# nodoc:
class BasicElement < Element
  attr_reader :element_name

  def initialize(element_name, **params)
    super(**params)
    @element_name = element_name
  end
end

# nodoc:
class TextElement < Element
  def initialize(text, on_click:)
    super(on_click: on_click)
    @text = text
  end

  def render_to_html
    elem = JS.global[:document].createTextNode(@text)
    register_events(elem)
    elem
  end
end

# nodoc:
class ComponentElement < Element
  # @param component [Component]
  def initialize(engine, component, parent_dom_id)
    @component = component
    @engine = engine
    ctx = Context.new(@engine, parent_dom_id: parent_dom_id)
    @component.render(ctx)

    super(on_click: nil, children: ctx.elements)
  end

  def render_to_html
    element = JS.global[:document].createElement('div')

    children.map do |child_element|
      element.appendChild(child_element.render_to_html)
    end

    element
  end

  def element_name
    @component.class.name
  end
end

# nodoc:
class Context
  BASIC_ELEMENTS = %w[
    h1
    div
    br
    table
    th
    tr
    td
    caption
    colgroup
    col
    thead
    tbody
    tfoot
    button
  ].freeze
  attr_reader :elements, :engine, :parent_dom_id, :element_idx

  def initialize(engine, parent_dom_id: '')
    @parent_dom_id = parent_dom_id
    @element_idx = 0
    @elements = []
    @engine = engine

    create_basic_elements
  end

  def create_basic_elements
    BASIC_ELEMENTS.each do |element_name|
      define_singleton_method(element_name) do |**attributes, &block|
        create(BasicElement.new(element_name, **attributes), block: block)
      end
    end
  end

  def text(text, on_click: nil)
    create(TextElement.new(text, on_click: on_click))
  end

  # @param component [Component]
  def component(component_class, **params)
    dom_id = parent_dom_id + ".ComponentElement[#{component_class.name}][#{element_idx}]"

    initialized_component = nil

    if engine.components[dom_id].nil?
      initialized_component = component_class.new(engine, params)
      initialized_component.setup
      engine.components[dom_id] = initialized_component
    else
      initialized_component = engine.components[dom_id]
    end

    element = ComponentElement.new(engine, initialized_component, parent_dom_id)
    @elements << element
    element
  end

  private

  def create(element, block: nil)
    ctx = Context.new(engine,
                      parent_dom_id: "#{parent_dom_id}.#{element.class.name}[#{element.element_name}][#{element_idx}]")
    @element_idx += 1

    block&.call(ctx)
    element.children = ctx.elements

    @elements << element
    element
  end
end

# nodoc:
class ChangeListener
  def initialize(value, change_callback)
    @value = value
    @change_callback = change_callback
  end

  def value=(new_value)
    @value = new_value
    @change_callback.call(new_value)
  end

  attr_reader :value
end

# nodoc:
class Component
  attr_reader :engine

  def initialize(engine, params)
    @engine = engine

    props.each do |prop|
      value = params[prop]

      define_singleton_method(prop.to_s) do
        value
      end
    end

    data.each do |data_key, data_value|
      change_listner = ChangeListener.new(data_value, lambda do |new_value|
        send("watch_#{data_key}", new_value) if respond_to?("watch_#{data_key}")
        @engine.render
      end)

      define_singleton_method("#{data_key}=") do |value|
        change_listner.value = value if change_listner.value != value
      end

      define_singleton_method(data_key.to_s) do
        change_listner.value
      end
    end
  end

  def props
    []
  end

  def data
    {}
  end

  def setup; end

  def render(_ctx)
    raise NotImplementedError
  end
end

# nodoc:
class Engine
  attr_accessor :components

  def initialize(start_component)
    @root_element = nil
    @start_component_class = start_component
    @components = {}
  end

  def render
    start_time = Time.now
    JS.global[:document][:body][:innerHTML] = 'Rendering...'
    @ctx = Context.new(self, parent_dom_id: 'root')
    @start_component = @ctx.component(@start_component_class)
    JS.global[:document][:body][:innerHTML] = ''

    rendered = @start_component.render_to_html

    end_time = Time.now

    JS.global[:document][:body].appendChild(
      JS.global[:document].createTextNode("It took #{end_time - start_time} seconds to render")
    )

    JS.global[:document][:body].appendChild(rendered)
  rescue StandardError => e
    puts e
    puts e.backtrace
  end
end
