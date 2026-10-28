defmodule Mix.Tasks.Multitenancy.Gen.Theme do
  @shortdoc "Generates a new theme under themes/"

  @moduledoc """
  Generates a theme skeleton.

      $ mix multitenancy.gen.theme alpha
      $ mix multitenancy.gen.theme alpha --no-live

  Creates `themes/alpha` with the `Themes.Alpha` theme module, router,
  layouts, gettext backend, a page controller whose templates fall back to
  `MyAppWeb.PageHTML`, a LiveView (unless `--no-live`), assets and default
  settings.

  ## Options

    * `--web-module` - base web module, defaults to `MyAppWeb`
    * `--no-live` - skip the sample LiveView
  """

  use Mix.Task

  import Mix.Generator

  @switches [live: :boolean, web_module: :string]

  @templates [
    {"theme.ex", "lib/<%= name %>.ex"},
    {"router.ex", "lib/<%= name %>/router.ex"},
    {"gettext.ex", "lib/<%= name %>/gettext.ex"},
    {"layouts.ex", "lib/<%= name %>/layouts.ex"},
    {"root.html.heex", "lib/<%= name %>/layouts/root.html.heex"},
    {"page_controller.ex", "lib/<%= name %>/page_controller.ex"},
    {"page_html.ex", "lib/<%= name %>/page_html.ex"},
    {"counter_live.ex", "lib/<%= name %>/counter_live.ex"},
    {"app.css", "assets/css/app.css"},
    {"app.js", "assets/js/app.js"},
    {"settings.yml", "config/settings.yml"}
  ]

  @impl true
  def run(args) do
    {opts, argv} = OptionParser.parse!(args, strict: @switches)

    name =
      case argv do
        [name] -> name |> Macro.underscore() |> String.replace("-", "_")
        _ -> Mix.raise("expected a single theme name, e.g.: mix multitenancy.gen.theme alpha")
      end

    app = Mix.Project.config()[:app] |> to_string()
    root = Path.join(Multitenancy.themes_path(), name)

    if File.exists?(root), do: Mix.raise("#{root} already exists")

    assigns = [
      name: name,
      module: inspect(Multitenancy.theme_module(name)),
      app: app,
      web_module: opts[:web_module] || Macro.camelize(app) <> "Web",
      web_path: "lib/#{app}_web",
      live: Keyword.get(opts, :live, true),
      base_css?: File.exists?("assets/css/app.css"),
      base_js?: File.exists?("assets/js/app.js")
    ]

    for {source, target} <- @templates, source != "counter_live.ex" or assigns[:live] do
      content = EEx.eval_file(template_path(source), assigns: assigns)
      create_file(Path.join(root, EEx.eval_string(target, name: name)), content)
    end

    create_file(Path.join(root, "lib/#{name}/page_html/.gitkeep"), "")

    Mix.shell().info("""

    Theme #{name} generated. Make sure that:

      * mix.exs compiles themes: elixirc_paths: ["lib" | Path.wildcard("themes/*/lib")]
      * a site points to it in your sites file:

          #{name}:
            theme: #{name}
            hosts: [#{name}.localtest.me]

      * the assets are built: mix multitenancy.assets #{name}
    """)
  end

  defp template_path(source) do
    Application.app_dir(:multitenancy_phoenix, Path.join("priv/templates/multitenancy.gen.theme", source))
  end
end
