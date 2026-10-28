defmodule Multitenancy.LiveView do
  @moduledoc """
  `on_mount` hook resolving the site from the socket host, for both the
  disconnected and the connected mount.

      live_session :default, on_mount: [Multitenancy.LiveView] do
        live "/counter", CounterLive
      end

  Assigns `:current_site` and `:current_theme`.
  """

  import Phoenix.Component, only: [assign: 3]

  def on_mount(:default, _params, _session, socket) do
    with %URI{host: host} <- socket.host_uri,
         {:ok, site} <- Multitenancy.resolver().resolve(host) do
      Multitenancy.Locale.put(site)
      {:cont, socket |> assign(:current_site, site) |> assign(:current_theme, site.theme)}
    else
      _ -> {:cont, socket}
    end
  end
end
