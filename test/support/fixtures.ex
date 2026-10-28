defmodule Fixture.Layouts do
  use Phoenix.Component

  slot :inner_block, required: true
  def wrap(assigns), do: ~H|<div class="base">{render_slot(@inner_block)}</div>|
end

defmodule Fixture.PageHTML do
  use Phoenix.Component
  alias Fixture.Layouts

  embed_templates "base_html/*"
end

defmodule Fixture.PageController do
  use Phoenix.Controller, formats: [:html]
  use Multitenancy.Controller

  plug :accepts, ["html"]
  plug :put_theme_view

  def show(conn, _params), do: render(conn, :show)
end

defmodule Fixture.PlatformRouter do
  use Phoenix.Router

  get "/", Fixture.PageController, :show
end

defmodule Themes.Fixture do
  use Multitenancy.Theme, name: "fixture", root: Path.expand("theme", __DIR__)
end

defmodule Themes.Fixture.Layouts do
  use Phoenix.Component

  slot :inner_block, required: true
  def wrap(assigns), do: ~H|<div class="theme">{render_slot(@inner_block)}</div>|
end

defmodule Themes.Fixture.PageHTML do
  use Phoenix.Component
  use Multitenancy.HTML
  alias Themes.Fixture.Layouts

  embed_theme_templates("page_html/*",
    root: "theme/lib",
    base: Fixture.PageHTML,
    base_pattern: "base_html/*"
  )
end

defmodule Themes.Fixture.Router do
  use Phoenix.Router

  get "/", Fixture.PageController, :show
  get "/theme-only", Fixture.PageController, :show
end

defmodule Fixture.StaticResolver do
  @behaviour Multitenancy.SiteResolver

  @impl true
  def resolve("fixture.test") do
    {:ok, %Multitenancy.Site{slug: "fixture", theme: Themes.Fixture.__theme__(), hosts: ["fixture.test"]}}
  end

  def resolve(_host), do: :error
end
