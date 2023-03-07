# frozen_string_literal: true

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

  attr_reader :engine, :element

  def initialize(engine, parent_dom_id, attributes)
    @engine = engine
    @parent_dom_id = parent_dom_id
    @attributes = attributes
    reset

    create_basic_elements
    setup_props
    setup_data
  rescue StandardError => e
    raise "/#{self.class.name}: #{e}"
  end

  def reset
    @element = BasicElement.new(self, 'div')
    @element_idx = 0
  end

  def props
    []
  end

  def data
    {}
  end

  def setup; end

  def render
    raise 'Render method not defined, all components should define a render method!'
  end

  def text(text, **attributes)
    create(TextElement.new(self, text, **attributes))
  end

  # @param component [Component]
  def component(component_class, **params)
    dom_id = @parent_dom_id + ".ComponentElement[#{component_class.name}][#{@element_idx}]"

    initialized_component = engine.find_or_initialize_component(dom_id, component_class, **params)

    create(ComponentElement.new(engine, initialized_component))
  end

  private

  def create_basic_elements
    BASIC_ELEMENTS.each do |element_name|
      if respond_to?(element_name.to_s)
        raise "Failed to add html template method #{element_name}, make sure you do not create methods with the same name as a html tag"
      end

      define_singleton_method(element_name) do |**attributes, &block|
        create(BasicElement.new(self, element_name, **attributes), block: block)
      end
    end
  end

  def setup_props
    props.each do |prop|
      value = @attributes[prop]

      if respond_to?(prop.to_s)
        raise "Failed to add property #{prop}, make sure you do not create methods with the same name as a property"
      end

      define_singleton_method(prop.to_s) do
        value
      end
    end
  end

  def setup_data
    data.each do |data_key, data_value|
      change_listner = ChangeListener.new(data_value, lambda do |new_value|
        send("watch_#{data_key}", new_value) if respond_to?("watch_#{data_key}")
        @engine.needs_render = true
      end)

      if respond_to?("#{data_key}=")
        raise "#{data_key} setter is already defined in class, make sure you do not create methods with the same name as data variables"
      end
      if respond_to?(data_key.to_s)
        raise "#{data_key} getter is already defined in class, make sure you do not create methods with the same name as data variables"
      end

      define_singleton_method("#{data_key}=") do |value|
        change_listner.value = value if change_listner.value != value
      end

      define_singleton_method(data_key.to_s) do
        change_listner.value
      end
    end
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
