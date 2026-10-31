defmodule <%= @module %>.PageHTML do
  @moduledoc "Page templates of the <%= @name %> theme, falling back to the base app."

  use <%= @module %>, :html

  embed_theme_templates "page_html/*", base: <%= @web_module %>.PageHTML
end
