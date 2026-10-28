defmodule <%= @module %>.PageHTML do
  use <%= @module %>, :html

  embed_theme_templates "page_html/*", base: <%= @web_module %>.PageHTML
end
