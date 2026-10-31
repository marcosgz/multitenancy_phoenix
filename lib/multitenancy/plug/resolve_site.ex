defmodule Multitenancy.Plug.ResolveSite do
  @moduledoc """
  Resolves the request into a site and assigns `:current_site` and
  `:current_theme`. Hosts in `:platform_hosts` are left untouched so they
  can be served by the platform router. Any other unknown host gets a 404,
  except under `:platform_paths`, which are served on every host.

      plug Multitenancy.Plug.ResolveSite,
        resolver: Multitenancy.SiteResolver.YAML,
        platform_hosts: ["localhost"],
        platform_paths: ["/admin"]

  The resolver's `c:Multitenancy.SiteResolver.resolve_conn/1` is used when
  defined, `c:Multitenancy.SiteResolver.resolve/1` with the host otherwise.
  """

  @behaviour Plug

  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, opts) do
    resolver = opts[:resolver] || Multitenancy.resolver()
    platform_hosts = opts[:platform_hosts] || Multitenancy.platform_hosts()
    platform_paths = opts[:platform_paths] || Multitenancy.platform_paths()

    if conn.host in platform_hosts, do: conn, else: resolve_site(conn, resolver, platform_paths)
  end

  defp resolve_site(conn, resolver, platform_paths) do
    case resolve(resolver, conn) do
      {:ok, site} ->
        Multitenancy.Locale.put(site)
        put_site(conn, site)

      :error ->
        if Multitenancy.platform_path?(conn.path_info, platform_paths),
          do: conn,
          else: conn |> send_resp(404, "Not Found") |> halt()
    end
  end

  @doc "Resolves `conn` with `resolver`."
  def resolve(resolver, conn) do
    Code.ensure_loaded(resolver)

    if function_exported?(resolver, :resolve_conn, 1),
      do: resolver.resolve_conn(conn),
      else: resolver.resolve(conn.host)
  end

  @doc "Stores `site` and its theme in the connection."
  def put_site(conn, site) do
    conn
    |> put_private(:multitenancy_site, site)
    |> assign(:current_site, site)
    |> assign(:current_theme, site.theme)
  end
end
