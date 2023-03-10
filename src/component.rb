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
    @components_using_data = {}
    @data_keys = []
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

  private

  def emit(**events)
    events.each do |event_key, event_value|
      @attributes.each do |attr_key, attr_value|
        if event_key == attr_key
          attr_value.call(event_value)
          return
        end
      end
    end

    raise "Unable to find receiver for event #{event_name}"
  end

  def render
    raise 'Render method not defined, all components should define a render method!'
  end

  def text(text, **attributes)
    create(TextElement.new(self, text, **attributes))
  end

  # @param component [Component]
  def component(component_class, **params)
    dom_id = @parent_dom_id + ".ComponentElement[#{component_class.name}][#{@element_idx}]"

    if params[:model]
      params[:input!] = lambda do |changed|
        send("#{params[:model]}=", changed)
      end
    end

    initialized_component = engine.find_or_initialize_component(dom_id, component_class, **params)

    params.each do |param_key, _param_value|
      @components_using_data[param_key] = initialized_component if @data_keys.include?(param_key.to_sym)
    end

    create(ComponentElement.new(engine, initialized_component))
  end

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
      @data_keys << data_key
      change_listner = ChangeListener.new(data_value, lambda do |new_value|
        send("watch_#{data_key}", new_value) if respond_to?("watch_#{data_key}")

        # Send changed value to child component watchers, only if they use this value though.
        if @components_using_data.key?(data_key)
          # We also need to redefine the property method
          @components_using_data[data_key].define_singleton_method(data_key.to_s) do
            new_value
          end

          if @components_using_data[data_key].respond_to?("watch_#{data_key}")
            @components_using_data[data_key].send("watch_#{data_key}", new_value)
          end
        end

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

  def set_timeout(timeout: 0, &block)
    JS.global.setTimeout(-> { block.call }, timeout)
  end

  def fetch(url, &block)
    promise = JS.global.fetch(url)
    promise.call(:then, lambda do |response|
      response.text.call(:then, lambda do |text|
        block.call(text)
      end)
    end)
  end

  def search_params
    JS.eval('return new URLSearchParams(window.location.search)')
  end

  def set_search_param(param, value)
    JS.eval("url = new URL(window.location); url.searchParams.set('#{param}', '#{value}'); window.history.pushState('', '', url);")
  end
end
