# nodoc:
class Element
  attr_accessor :attributes, :children

  def initialize(**attributes)
    @children = attributes[:children] || []
    @attributes = attributes
  end

  def render_to_html(full:)
    element = JS.global[:document].createElement(element_name)

    assign_attributes(element)
    register_events(element)

    if full
      children.map do |child_element|
        element.appendChild(child_element.render_to_html(full: true))
      end
    end

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
    event_name = event_name.to_s

    event_handler = attributes["#{event_name}!".to_sym]

    old_listners = element.getEventListeners(event_name)

    unless old_listners.eql?(JS::Undefined)
      for i in 0...old_listners[:length].to_i
        element.removeEventListener(event_name, element.getEventListeners(event_name)[i][:listener])
      end
    end

    element.addEventListener(event_name) do |event|
      event_handler&.call(event)
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

  def render_to_html(full:)
    JS.global[:document].createTextNode(@text)
  end
end

# nodoc:
class ComponentElement < Element
  # @param component [Component]
  def initialize(engine, component, root: false)
    @component = component
    @engine = engine
    @root = root

    @component.reset
    @component.render

    super(children: @component.element.children)
  end

  def render_to_html(full:)
    element = JS.global[:document].createElement(@root ? 'body' : 'div')

    if full
      children.map do |child_element|
        element.appendChild(child_element.render_to_html(full: true))
      end
    end

    element
  end

  def element_name
    @component.class.name
  end
end
