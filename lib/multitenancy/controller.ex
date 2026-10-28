defmodule Multitenancy.Controller do
  @moduledoc """
  Helpers for base controllers that are also routed from theme routers.

      defmodule MyAppWeb.PageController do
        use MyAppWeb, :controller
        plug :put_theme_view
      end

  `put_theme_view/2` swaps every view (e.g. `MyAppWeb.PageHTML`) for the
  theme counterpart (`Themes.Alpha.PageHTML`) when the theme defines it.
  """

  alias Multitenancy.Theme

  defmacro __using__(_opts) do
    quote do
      import Multitenancy.Controller, only: [put_theme_view: 2]
    end
  end

  def put_theme_view(conn, _opts \\ []) do
    case conn.assigns[:current_theme] do
      %Theme{module: theme_module} ->
        views =
          for {format, view} <- conn.private[:phoenix_view] || %{}, format != :_ do
            {format, theme_view(theme_module, view)}
          end

        Phoenix.Controller.put_view(conn, views)

      _ ->
        conn
    end
  end

  @doc "Maps `MyAppWeb.PageHTML` to `Themes.Alpha.PageHTML` when it exists."
  def theme_view(theme_module, view) do
    [_base_namespace | rest] = Module.split(view)
    candidate = Module.concat([theme_module | rest])
    if Code.ensure_loaded?(candidate), do: candidate, else: view
  end
end
