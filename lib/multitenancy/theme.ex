defmodule Multitenancy.Theme do
  @moduledoc """
  Declares a theme.

      defmodule Themes.Alpha do
        use Multitenancy.Theme, name: "alpha"
      end

  By convention the theme router is `Themes.Alpha.Router`, its layouts module
  `Themes.Alpha.Layouts` and its root directory `themes/alpha`. Each can be
  overridden with the `:router`, `:layouts` and `:root` options.

  Default settings are read at compile time from `<root>/config/settings.yml`
  and are deep merged under each site's own settings.
  """

  @enforce_keys [:name, :module, :router, :layouts, :root]
  defstruct [:name, :module, :router, :layouts, :root, settings: %{}]

  @type t :: %__MODULE__{
          name: String.t(),
          module: module,
          router: module,
          layouts: module,
          root: Path.t(),
          settings: map
        }

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      name = opts |> Keyword.fetch!(:name) |> to_string()
      root = Path.expand(opts[:root] || Path.join(Multitenancy.themes_path(), name))
      settings_path = Path.join(root, "config/settings.yml")

      @external_resource settings_path
      @multitenancy_theme %Multitenancy.Theme{
        name: name,
        module: __MODULE__,
        router: opts[:router] || Module.concat(__MODULE__, Router),
        layouts: opts[:layouts] || Module.concat(__MODULE__, Layouts),
        root: root,
        settings: Multitenancy.Settings.load_file(settings_path)
      }

      def __theme__, do: @multitenancy_theme
    end
  end
end
