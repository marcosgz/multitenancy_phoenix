defmodule Multitenancy.Plug.ResolveSite do
  @moduledoc """
  Resolves `conn.host` into a site and assigns `:current_site` and
  `:current_theme`. Hosts in `:platform_hosts` are left untouched so they
  can be served by the platform router; any other unknown host gets a 404.

      plug Multitenancy.Plug.ResolveSite,
        resolver: Multitenancy.SiteResolver.YAML,
        platform_hosts: ["localhost"]
  """

  @behaviour Plug

  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, opts) do
    resolver = opts[:resolver] || Multitenancy.resolver()
    platform_hosts = opts[:platform_hosts] || Multitenancy.platform_hosts()

    if conn.host in platform_hosts do
      conn
    else
      case resolver.resolve(conn.host) do
        {:ok, site} ->
          Multitenancy.Locale.put(site)
          put_site(conn, site)

        :error ->
          conn |> send_resp(404, "Not Found") |> halt()
      end
    end
  end

  @doc "Stores `site` and its theme in the connection."
  def put_site(conn, site) do
    conn
    |> put_private(:multitenancy_site, site)
    |> assign(:current_site, site)
    |> assign(:current_theme, site.theme)
  end
end
