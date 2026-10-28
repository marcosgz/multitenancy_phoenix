defmodule Multitenancy.SiteResolver do
  @moduledoc """
  Resolves a request host into a `Multitenancy.Site`.

  Implement this behaviour to load sites from any source (database,
  external API, ...) and configure it with:

      config :multitenancy_phoenix, resolver: MyApp.SiteResolver
  """

  @callback resolve(host :: String.t()) :: {:ok, Multitenancy.Site.t()} | :error
end
