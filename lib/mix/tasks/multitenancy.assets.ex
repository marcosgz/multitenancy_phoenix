defmodule Mix.Tasks.Multitenancy.Assets do
  @shortdoc "Builds the CSS and JS bundles of every theme"

  @moduledoc """
  Builds `themes/<name>/assets/css/app.css` with tailwind and
  `themes/<name>/assets/js/app.js` with esbuild into
  `priv/static/themes/<name>/app.{css,js}`.

      $ mix multitenancy.assets            # build all themes
      $ mix multitenancy.assets alpha      # build only alpha
      $ mix multitenancy.assets --minify   # production build
      $ mix multitenancy.assets --watch    # rebuild on change

  The tailwind version and the esbuild version and `:env` (e.g. `NODE_PATH`)
  are taken from the host application configuration:

      config :esbuild, version: "0.25.4", my_app: [env: %{"NODE_PATH" => ...}]
      config :tailwind, version: "4.1.12"

  Extra esbuild arguments shared by every theme bundle, such as aliases to the
  base application's modules or code splitting, go in `:esbuild_args`. Bundles
  are written with `--outdir`, so `--splitting --format=esm` works as is:

      config :multitenancy_phoenix,
        esbuild_args: ~w(--format=esm --splitting --alias:@app=./assets/js)

  Use it as a development watcher in the endpoint:

      watchers: [themes: {Mix.Tasks.Multitenancy.Assets, :run, [~w(--watch)]}]
  """

  use Mix.Task

  @compile {:no_warn_undefined, [Tailwind, Esbuild]}
  @switches [watch: :boolean, minify: :boolean]

  @impl true
  def run(args) do
    {opts, names} = OptionParser.parse!(args, strict: @switches)
    themes = if names == [], do: Multitenancy.theme_names(), else: names

    for app <- [:tailwind, :esbuild], do: {:ok, _} = Application.ensure_all_started(app)

    jobs = Enum.flat_map(themes, &jobs(&1, opts))

    if opts[:watch] do
      jobs |> Enum.map(&Task.async/1) |> Task.await_many(:infinity)
    else
      for job <- jobs, (status = job.()) != 0 do
        Mix.raise("theme asset build failed with status #{status}")
      end
    end

    :ok
  end

  defp jobs(theme, opts) do
    root = Path.join(Multitenancy.themes_path(), theme)
    output = Path.join("priv/static/themes", theme)

    Enum.reject(
      [
        css_job(theme, Path.join(root, "assets/css/app.css"), output, opts),
        js_job(theme, Path.join(root, "assets/js/app.js"), output, opts)
      ],
      &is_nil/1
    )
  end

  defp css_job(theme, input, output, opts) do
    if File.exists?(input) do
      profile = String.to_atom("multitenancy_#{theme}_css")

      args =
        ["--input=#{input}", "--output=#{Path.join(output, "app.css")}"] ++
          flag(opts[:minify], "--minify") ++ flag(opts[:watch], "--watch")

      Application.put_env(:tailwind, profile, args: args, cd: File.cwd!())
      fn -> Tailwind.install_and_run(profile, []) end
    end
  end

  defp js_job(theme, input, output, opts) do
    if File.exists?(input) do
      profile = String.to_atom("multitenancy_#{theme}_js")

      args =
        [input, "--bundle", "--target=es2022", "--outdir=#{output}"] ++
          ~w(--external:/fonts/* --external:/images/*) ++
          Application.get_env(:multitenancy_phoenix, :esbuild_args, []) ++
          flag(opts[:minify], "--minify") ++ flag(opts[:watch], ["--sourcemap=inline", "--watch"])

      Application.put_env(:esbuild, profile, args: args, cd: File.cwd!(), env: esbuild_env())
      fn -> Esbuild.install_and_run(profile, []) end
    end
  end

  defp esbuild_env do
    app = Mix.Project.config()[:app]
    get_in(Application.get_env(:esbuild, app, []), [:env]) || %{}
  end

  defp flag(true, value), do: List.wrap(value)
  defp flag(_, _value), do: []
end
