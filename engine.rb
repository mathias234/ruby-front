# frozen_string_literal: true

require 'js'

# nodoc:
class Element
  attr_accessor :attributes, :children

  def initialize(**attributes)
    @children = attributes[:children] || []
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
    element[:type] = attributes[:type] if attributes[:type]
  end

  def register_events(element)
    register_event(element, :click)
    register_event(element, :input)
  end

  def register_event(element, event_name)
    event_handler = attributes["#{event_name}!".to_sym]

    return unless event_handler

    element.addEventListener(event_name.to_s) do |event|
      event_handler.call(event)
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
  attr_reader :element_name

  def initialize(text, **params)
    super(**params)
    @text = text
    @element_name = 'text'
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
  def initialize(engine, component, _parent_dom_id)
    @component = component
    @engine = engine
    @component.reset
    @component.render

    super(children: @component.element.children)
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
    input
  ].freeze

  attr_reader :engine, :parent_dom_id, :element

  def initialize(engine, parent_dom_id, params)
    @engine = engine
    @parent_dom_id = parent_dom_id
    reset

    create_basic_elements

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

  def reset
    @element = BasicElement.new('div')
    @element_idx = 0
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

  def create_basic_elements
    BASIC_ELEMENTS.each do |element_name|
      define_singleton_method(element_name) do |**attributes, &block|
        create(BasicElement.new(element_name, **attributes), block: block)
      end
    end
  end

  def text(text, **attributes)
    create(TextElement.new(text, **attributes))
  end

  # @param component [Component]
  def component(component_class, **params)
    dom_id = parent_dom_id + ".ComponentElement[#{component_class.name}][#{@element_idx}]"

    initialized_component = engine.find_or_initialize_component(dom_id, component_class, **params)

    create(ComponentElement.new(engine, initialized_component, parent_dom_id))
  end

  def create(element, block: nil)
    @element_idx += 1

    @element.children << element
    last_element = @element
    @element = element

    last_element_idx = @element_idx
    block&.call
    @element_idx = last_element_idx

    @element = last_element
  end
end

# nodoc:
class Engine
  def initialize(start_component)
    @root_element = nil
    @start_component_class = start_component
    @components = {}
  end

  def find_or_initialize_component(dom_id, component_class, **params)
    if @components[dom_id].nil?
      initialized_component = component_class.new(self, dom_id, params)
      initialized_component.setup
      @components[dom_id] = initialized_component
    end

    @components[dom_id]
  end

  def render
    start_time = Time.now
    JS.global[:document][:body][:innerHTML] = 'Rendering...'

    initialized_component = find_or_initialize_component('root', @start_component_class)

    start_component = ComponentElement.new(self, initialized_component, 'root')

    JS.global[:document][:body][:innerHTML] = ''

    rendered = start_component.render_to_html

    end_time = Time.now

    JS.global[:document][:body].appendChild(
      JS.global[:document].createTextNode("It took #{end_time - start_time} seconds to render")
    )

    JS.global[:document][:body].appendChild(rendered)
  end
end
