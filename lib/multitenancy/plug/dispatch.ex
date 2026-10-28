defmodule Multitenancy.Plug.Dispatch do
  @moduledoc """
  Hands the request over to the current theme's router, or to the
  `:platform` router when no site was resolved. Replaces the
  `plug MyAppWeb.Router` line at the end of the endpoint.

      plug Multitenancy.Plug.Dispatch, platform: MyAppWeb.Router
  """

  @behaviour Plug

  @impl true
  def init(opts), do: Keyword.fetch!(opts, :platform)

  @impl true
  def call(%Plug.Conn{private: %{multitenancy_site: site}} = conn, _platform) do
    route(conn, site.theme.router)
  end

  def call(conn, platform), do: route(conn, platform)

  defp route(conn, router), do: router.call(conn, router.init([]))
end
