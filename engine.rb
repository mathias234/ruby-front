# frozen_string_literal: true

require 'js'

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

      if respond_to?("#{prop}")
        raise "Failed to add property #{prop}, make sure you do not create methods with the same name as a property"
      end

      define_singleton_method(prop.to_s) do
        value
      end
    end

    data.each do |data_key, data_value|
      change_listner = ChangeListener.new(data_value, lambda do |new_value|
        send("watch_#{data_key}", new_value) if respond_to?("watch_#{data_key}")
        @engine.render
      end)

      if respond_to?("#{data_key}=")
        raise "#{data_key} setter is already defined in class, make sure you do not create methods with the same name as data variables"
      end
      if respond_to?("#{data_key}")
        raise "#{data_key} getter is already defined in class, make sure you do not create methods with the same name as data variables"
      end

      define_singleton_method("#{data_key}=") do |value|
        change_listner.value = value if change_listner.value != value
      end

      define_singleton_method(data_key.to_s) do
        change_listner.value
      end
    end
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

  def create_basic_elements
    BASIC_ELEMENTS.each do |element_name|
      if respond_to?("#{element_name}")
        raise "Failed to add html template method #{element_name}, make sure you do not create methods with the same name as a html tag"
      end

      define_singleton_method(element_name) do |**attributes, &block|
        create(BasicElement.new(self, element_name, **attributes), block: block)
      end
    end
  end

  def text(text, **attributes)
    create(TextElement.new(self, text, **attributes))
  end

  # @param component [Component]
  def component(component_class, **params)
    dom_id = parent_dom_id + ".ComponentElement[#{component_class.name}][#{@element_idx}]"

    initialized_component = engine.find_or_initialize_component(dom_id, component_class, **params)

    create(ComponentElement.new(engine, initialized_component))
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
  rescue StandardError => e
    raise "Error in #{@start_component_class.name}#{e}"
  end

  def render
    start_time = Time.now
    initialized_component = find_or_initialize_component('root', @start_component_class)

    start_component = ComponentElement.new(self, initialized_component, root: true)
    end_time = Time.now
    puts "Took #{end_time - start_time} seconds to build virtual dom"

    start_time = Time.now
    diff_and_update_html_dom(start_component, JS.global[:document][:body])
    end_time = Time.now
    puts "Took #{end_time - start_time} seconds to diff and update html dom"
  end

  def diff_and_update_html_dom(new_node_elem, node)
    new_node = new_node_elem.render_to_html(full: false)

    if !node[:nodeType].strictly_eql?(new_node[:nodeType]) || !node[:nodeName].strictly_eql?(new_node[:nodeName])
      node[:parentNode].replaceChild(new_node_elem.render_to_html(full: true), node)
      return true
    end

    case node[:nodeType].to_i
    when 1 # ElementNode
      # Update event registration
      new_node_elem.register_events(node)
      new_node_elem.bind_model(node)

      # Remove old attributes
      node_attrs = node[:attributes]
      (0...node_attrs[:length].to_i).each do |i|
        attr = node_attrs[i]
        next if attr.strictly_eql?(JS::Undefined)

        node.removeAttribute(attr[:name])
      end

      # Add new attributes
      (0...new_node[:attributes][:length].to_i).each do |i|
        attr = new_node[:attributes].item(i)
        node.setAttribute(attr[:name], attr[:value])
      end

      # Update children
      (0...new_node_elem.children.length).each do |i|
        new_child_node = new_node_elem.children[i]
        child_node = node[:childNodes][i]

        if child_node.eql?(JS::Null)
          node.appendChild(new_child_node.render_to_html(full: true))
        else
          diff_and_update_html_dom(new_child_node, child_node)
        end
      end

      # Remove excess children
      node.removeChild(node[:lastChild]) while node[:childNodes][:length].to_i > new_node_elem.children.length
    when 3 # TextNode
      unless node[:textContent].strictly_eql?(new_node[:textContent])
        node[:parentNode].replaceChild(new_node, node)
        return true
      end
    end

    false
  end
end
