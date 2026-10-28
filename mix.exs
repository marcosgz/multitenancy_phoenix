defmodule Multitenancy.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/marcosgz/multitenancy_phoenix"

  def project do
    [
      app: :multitenancy_phoenix,
      version: @version,
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Multi-site, theme-based multitenancy for Phoenix applications",
      source_url: @source_url,
      package: [
        licenses: ["MIT"],
        links: %{"GitHub" => @source_url},
        files: ~w(lib priv mix.exs README.md LICENSE.txt)
      ],
      docs: [main: "readme", extras: ["README.md"], source_ref: "v#{@version}"]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.8"},
      {:phoenix_live_view, "~> 1.1"},
      {:plug, "~> 1.16"},
      {:yaml_elixir, "~> 2.11"},
      {:jason, "~> 1.4"},
      {:gettext, "~> 1.0", optional: true},
      {:tailwind, "~> 0.3", optional: true},
      {:esbuild, "~> 0.9", optional: true}
    ]
  end
end
