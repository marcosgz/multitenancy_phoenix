defmodule Themes.Alpha.Layouts do
  use Themes.Alpha, :html

  embed_templates "layouts/*"

  attr :flash, :map, required: true
  attr :current_site, Multitenancy.Site, default: nil
  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class="navbar bg-brand text-white px-4 sm:px-6 lg:px-8">
      <a href="/" class="text-lg font-bold">
        {@current_site && @current_site.settings["title"]}
      </a>
    </header>

    <main class="px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  defdelegate flash_group(assigns), to: TwoSitesWeb.Layouts
  defdelegate theme_toggle(assigns), to: TwoSitesWeb.Layouts
end
