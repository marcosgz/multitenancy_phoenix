defmodule Multitenancy do
  @moduledoc """
  Host-resolved multi-site theming for Phoenix.

  A request host is resolved to a `Multitenancy.Site`, each site points to a
  theme living under `themes/<name>/`, and every theme is a self-contained
  slice of the application with its own router, controllers, templates,
  layouts, assets and gettext backend. Templates missing from a theme fall
  back to the base application (see `Multitenancy.HTML`).
  """

  alias Multitenancy.Theme

  @doc "Directory holding the themes, relative to the project root."
  def themes_path do
    Application.get_env(:multitenancy_phoenix, :themes_path, "themes")
  end

  @doc "Names of the theme directories found under `themes_path/0`."
  def theme_names(root \\ themes_path()) do
    root
    |> Path.join("*/lib")
    |> Path.wildcard()
    |> Enum.map(&(&1 |> Path.dirname() |> Path.basename()))
    |> Enum.sort()
  end

  @doc "The module conventionally defining the theme `name`, e.g. `Themes.MyStore`."
  def theme_module(name) do
    Module.concat(Themes, Macro.camelize(to_string(name)))
  end

  @doc "Fetches the theme definition for `name`."
  @spec theme(String.t() | atom) :: {:ok, Theme.t()} | :error
  def theme(name) do
    module = theme_module(name)

    if Code.ensure_loaded?(module) and function_exported?(module, :__theme__, 0) do
      {:ok, module.__theme__()}
    else
      :error
    end
  end

  @doc "Same as `theme/1` but raises `Multitenancy.ThemeNotFoundError`."
  @spec theme!(String.t() | atom) :: Theme.t()
  def theme!(name) do
    case theme(name) do
      {:ok, theme} -> theme
      :error -> raise Multitenancy.ThemeNotFoundError, name: name, module: theme_module(name)
    end
  end

  @doc "The configured `Multitenancy.SiteResolver` implementation."
  def resolver do
    Application.get_env(:multitenancy_phoenix, :resolver, Multitenancy.SiteResolver.YAML)
  end

  @doc "Hosts served by the platform router instead of a theme."
  def platform_hosts do
    Application.get_env(:multitenancy_phoenix, :platform_hosts, [])
  end

  @doc """
  Path prefixes served by the platform router on every host, such as an admin
  area or health checks shared by all sites.
  """
  def platform_paths do
    Application.get_env(:multitenancy_phoenix, :platform_paths, [])
  end

  @doc "Whether `path_info` falls under one of the `prefixes` (`\"/admin\"` matches `/admin/sites`)."
  @spec platform_path?([String.t()], [String.t()]) :: boolean
  def platform_path?(path_info, prefixes) do
    Enum.any?(prefixes, &List.starts_with?(path_info, String.split(&1, "/", trim: true)))
  end
end

defmodule Multitenancy.ThemeNotFoundError do
  defexception [:name, :module]

  @impl true
  def message(%{name: name, module: module}) do
    "theme #{inspect(name)} not found: expected #{inspect(module)} to `use Multitenancy.Theme`"
  end
end
