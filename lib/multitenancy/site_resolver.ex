defmodule Multitenancy.SiteResolver do
  @moduledoc """
  Resolves a request host into a `Multitenancy.Site`.

  Implement this behaviour to load sites from any source (database,
  external API, ...) and configure it with:

      config :multitenancy_phoenix, resolver: MyApp.SiteResolver
  """

  @callback resolve(host :: String.t()) :: {:ok, Multitenancy.Site.t()} | :error

  @doc """
  Resolves a site from the whole request, for lookups that need more than the
  host (a header, a path prefix, ...). When implemented, `Multitenancy.Plug.ResolveSite`
  calls it instead of `c:resolve/1`.
  """
  @callback resolve_conn(Plug.Conn.t()) :: {:ok, Multitenancy.Site.t()} | :error

  @optional_callbacks resolve_conn: 1
end
