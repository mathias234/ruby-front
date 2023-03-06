# frozen_string_literal: true

require('js')

def require_remote(file)
  file = JS.global.fetch(file).await
  eval file.text.await.to_s
end

require_remote('engine.rb')
require_remote('elements.rb')
require_remote('components/home.rb')
require_remote('components/index.rb')
require_remote('components/input_field.rb')
require_remote('components/page2.rb')
require_remote('components/paged_table.rb')

engine = Engine.new(Home)
engine.render
