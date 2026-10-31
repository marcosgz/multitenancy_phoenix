defmodule Multitenancy.Plug.Dispatch do
  @moduledoc """
  Hands the request over to the current theme's router, or to the
  `:platform` router when no site was resolved or the path is one of the
  `:platform_paths`. Replaces the `plug MyAppWeb.Router` line at the end of
  the endpoint.

      plug Multitenancy.Plug.Dispatch, platform: MyAppWeb.Router
  """

  @behaviour Plug

  @impl true
  def init(opts) do
    {Keyword.fetch!(opts, :platform), Keyword.get(opts, :platform_paths)}
  end

  @impl true
  def call(conn, {platform, platform_paths}) do
    case conn.private do
      %{multitenancy_site: site} ->
        if Multitenancy.platform_path?(conn.path_info, platform_paths || Multitenancy.platform_paths()),
          do: route(conn, platform),
          else: route(conn, site.theme.router)

      _ ->
        route(conn, platform)
    end
  end

  defp route(conn, router), do: router.call(conn, router.init([]))
end
