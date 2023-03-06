# How to run
Compile JS with esbuild
node `node make.cjs`
Start a simple webserver e.g `ruby -run -ehttpd . -p8000`, then open the browser and go to the server

# Example component

```ruby
class Example < Component
  def data
    {
      current_text: 'Test'
    }
  end

  def watch_current_text(new_value)
    puts "Current text changed into #{new_value}!"
  end

  def render
    div do
      text current_text
    end

    input model: :current_text, class_name: 'some_class', type: 'text'
  end
end
```

