defmodule Multitenancy.SiteResolver.YAML do
  @moduledoc """
  Resolves sites from a YAML file loaded once into `:persistent_term`.

      alpha:
        theme: alpha
        hosts: [alpha.example.com]
        locale: en
        settings:
          title: Alpha

  Add it to your supervision tree so the file is loaded at boot:

      {Multitenancy.SiteResolver.YAML, path: Application.app_dir(:my_app, "priv/sites.yml")}
  """

  @behaviour Multitenancy.SiteResolver

  alias Multitenancy.{Settings, Site}

  @key {__MODULE__, :hosts}

  def child_spec(opts) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [opts]}, restart: :transient}
  end

  def start_link(opts) do
    opts |> Keyword.fetch!(:path) |> load!()
    :ignore
  end

  @doc "Parses `path` and replaces the loaded sites."
  def load!(path) do
    sites = path |> YamlElixir.read_from_file!() |> Settings.normalize() |> Enum.map(&build_site/1)
    :persistent_term.put(@key, Map.new(for site <- sites, host <- site.hosts, do: {host, site}))
    sites
  end

  @doc "All loaded sites."
  def sites do
    @key |> :persistent_term.get(%{}) |> Map.values() |> Enum.uniq_by(& &1.slug)
  end

  @impl true
  def resolve(host) do
    case :persistent_term.get(@key, %{}) do
      %{^host => site} -> {:ok, site}
      _ -> :error
    end
  end

  defp build_site({slug, attrs}) do
    theme = Multitenancy.theme!(Map.get(attrs, "theme", slug))

    %Site{
      slug: to_string(slug),
      theme: theme,
      locale: attrs["locale"],
      hosts: List.wrap(attrs["hosts"]),
      settings: Settings.deep_merge(theme.settings, Settings.normalize(attrs["settings"]))
    }
  end
end
