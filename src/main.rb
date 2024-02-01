# frozen_string_literal: true

require('js')

def require_remote(file_path)
  file = JS.global.fetch(file_path).await
  code = file.text.await.to_s

  Kernel.eval(code, TOPLEVEL_BINDING, file_path)
end

require_remote('src/engine.rb')
require_remote('src/component.rb')
require_remote('src/elements.rb')
require_remote('components/home.rb')
require_remote('components/index.rb')
require_remote('components/input_field.rb')
require_remote('components/page2.rb')
require_remote('components/paged_table.rb')
require_remote('components/star_wars_characters.rb')

Engine.new(Home)

puts 'Engine finished..'
