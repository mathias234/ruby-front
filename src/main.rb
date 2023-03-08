# frozen_string_literal: true

require('js')

def require_remote(file)
  file = JS.global.fetch(file).await
  code = file.text.await.to_s

  eval(code.to_s)
end

require_remote('src/engine.rb')
require_remote('src/component.rb')
require_remote('src/elements.rb')
require_remote('components/home.rb')
require_remote('components/index.rb')
require_remote('components/input_field.rb')
require_remote('components/page2.rb')
require_remote('components/paged_table.rb')

Engine.new(Home)

puts 'Engine finished..'
