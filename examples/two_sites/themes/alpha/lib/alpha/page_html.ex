defmodule Themes.Alpha.PageHTML do
  use Themes.Alpha, :html

  embed_theme_templates "page_html/*", base: TwoSitesWeb.PageHTML
end
