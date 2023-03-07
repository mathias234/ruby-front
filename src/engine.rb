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
class Engine
  ELEMENT_TYPES = [
    ELEMENT_NODE = 1,
    TEXT_NODE = 3
  ].freeze

  attr_writer :needs_render

  def initialize(start_component)
    @root_element = nil
    @start_component_class = start_component
    @components = {}
    @needs_render = true

    task_worker = lambda do
      process_tasks
      JS.global.setTimeout(task_worker, 10)
    end

    JS.global.setTimeout(task_worker)
  end

  def find_or_initialize_component(dom_id, component_class, **params)
    if @components[dom_id].nil?
      initialized_component = component_class.new(self, dom_id, params)
      @components[dom_id] = initialized_component

      JS.global.setTimeout(lambda do
        initialized_component.setup
        self.needs_render = true
      end)

    end

    @components[dom_id]
  rescue StandardError => e
    raise "Error in #{@start_component_class.name}#{e}"
  end

  def process_tasks
    return unless @needs_render

    @needs_render = false

    render
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
    when ELEMENT_NODE
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
    when TEXT_NODE
      unless node[:textContent].strictly_eql?(new_node[:textContent])
        node[:parentNode].replaceChild(new_node, node)
        return true
      end
    else
      raise "Unexpected node type #{node[:nodeType]} when diffing!"
    end

    false
  end
end
