# How to run
This project uses vite, so just do:
`npm run dev`

And then run the tailwind cli watcher
`npx tailwindcss -i ./input.css -o ./dist/output.css --watch`

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

