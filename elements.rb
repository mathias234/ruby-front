# frozen_string_literal: true

# nodoc:
class Element
  attr_accessor :attributes, :children

  def initialize(component, **attributes)
    @children = attributes[:children] || []
    @attributes = attributes
    @component = component
  end

  def render_to_html(full:)
    element = JS.global[:document].createElement(element_name)

    assign_attributes(element)
    register_events(element)
    bind_model(element)

    if full
      children.map do |child_element|
        element.appendChild(child_element.render_to_html(full: true))
      end
    end

    element
  end

  def bind_model(element)
    return unless attributes[:model]

    unless @component.respond_to?("#{attributes[:model]}=")
      raise "Unable to bind model #{attributes[:model]} on #{element_name}, could not find data value"
    end

    element.addEventListener('input') do |event|
      @component.send("#{attributes[:model]}=", event[:target][:value])
    end

    element[:value] = @component.send(attributes[:model].to_s)
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
      (0...old_listners[:length].to_i).each do |_i|
        element.removeEventListener(event_name, element.getEventListeners(event_name)[0][:listener])
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

  def initialize(component, element_name, **params)
    super(component, **params)
    @element_name = element_name
  end
end

# nodoc:
class TextElement < Element
  attr_reader :element_name

  def initialize(component, text, **params)
    super(component, **params)
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

    super(component, children: @component.element.children)
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
