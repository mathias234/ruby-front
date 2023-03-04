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
    element[:value] = attributes[:value] if attributes[:value]
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

  def render_to_html(body: false)
    element = JS.global[:document].createElement(body ? 'body' : 'div')

    children.map do |child_element|
      element.appendChild(child_element.render_to_html)
    end

    element
  end

  def element_name
    @component.class.name
  end
end
