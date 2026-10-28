defmodule Themes.Beta.Layouts do
  use Themes.Beta, :html

  embed_templates "layouts/*"

  attr :flash, :map, required: true
  attr :current_site, Multitenancy.Site, default: nil
  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class="navbar border-b-4 border-brand px-4 sm:px-6 lg:px-8">
      <a href="/" class="text-lg font-bold text-brand">
        {@current_site && @current_site.settings["title"]}
      </a>
      <nav class="ml-auto space-x-4">
        <.link navigate={~p"/about"}>About</.link>
        <.link navigate={~p"/counter"}>Counter</.link>
      </nav>
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
