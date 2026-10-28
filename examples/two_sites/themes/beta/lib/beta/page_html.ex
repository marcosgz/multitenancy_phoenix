defmodule Themes.Beta.PageHTML do
  use Themes.Beta, :html

  embed_theme_templates "page_html/*", base: TwoSitesWeb.PageHTML
end
