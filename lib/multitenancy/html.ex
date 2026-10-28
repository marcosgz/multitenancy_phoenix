defmodule Multitenancy.HTML do
  @moduledoc """
  Embeds a theme's templates, falling back to the base application ones.

      defmodule Themes.Alpha.PageHTML do
        use Themes.Alpha, :html

        embed_theme_templates "page_html/*", base: MyAppWeb.PageHTML
      end

  Every template found in `page_html/` next to this file is compiled. Any
  template of `MyAppWeb.PageHTML` (looked up with the same pattern next to
  the base module source) that the theme does not override is compiled too,
  **inside the theme module**. A fallback template therefore resolves
  `<Layouts.app>`, `~p`, imported components and gettext through the theme,
  the same way Rails renders a fallback view within the theme layout.

  Function components defined directly in the base module are not copied;
  share them through an imported components module instead.

  ## Options

    * `:base` - the base HTML module (required)
    * `:root` - directory of the theme templates, defaults to the caller dir
    * `:base_root` - directory of the base templates, defaults to the base
      module source dir
    * `:base_pattern` - pattern for base templates, defaults to `pattern`
  """

  defmacro __using__(_opts) do
    quote do
      import Multitenancy.HTML, only: [embed_theme_templates: 2]
    end
  end

  defmacro embed_theme_templates(pattern, opts) do
    quote bind_quoted: [pattern: pattern, opts: opts] do
      for {name, path, body} <- Multitenancy.HTML.__compile__(__MODULE__, __DIR__, pattern, opts) do
        @external_resource path
        @file path
        def unquote(String.to_atom(name))(var!(assigns)) do
          _ = var!(assigns)
          unquote(body)
        end
      end
    end
  end

  @doc false
  def __compile__(module, dir, pattern, opts) do
    base = Keyword.fetch!(opts, :base)

    sources = [
      {Path.expand(opts[:root] || dir, dir), pattern},
      {base_root(base, opts), opts[:base_pattern] || pattern}
    ]

    engines = Phoenix.Template.engines()
    track(module, sources)

    sources
    |> Enum.flat_map(fn {root, pattern} -> Phoenix.Template.find_all(root, pattern, engines) end)
    |> Enum.uniq_by(&template_name/1)
    |> Enum.map(fn path ->
      name = template_name(path)
      engine = Map.fetch!(engines, path |> Path.extname() |> String.trim_leading(".") |> String.to_atom())
      {name, path, engine.compile(path, name)}
    end)
  end

  defp base_root(base, opts) do
    if root = opts[:base_root] do
      Path.expand(root)
    else
      Code.ensure_compiled!(base)
      base.__info__(:compile)[:source] |> to_string() |> Path.dirname()
    end
  end

  defp template_name(path), do: path |> Path.basename() |> Path.rootname() |> Path.rootname()

  defp track(module, sources) do
    unless Module.has_attribute?(module, :multitenancy_templates) do
      Module.register_attribute(module, :multitenancy_templates, accumulate: true)
      Module.put_attribute(module, :before_compile, __MODULE__)
    end

    for {root, pattern} <- sources do
      Module.put_attribute(module, :multitenancy_templates, {root, pattern, Phoenix.Template.hash(root, pattern)})
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    changed =
      env.module
      |> Module.get_attribute(:multitenancy_templates)
      |> Enum.reduce(false, fn {root, pattern, hash}, acc ->
        quote do
          unquote(acc) or unquote(hash) != Phoenix.Template.hash(unquote(root), unquote(pattern))
        end
      end)

    quote do
      @doc false
      def __mix_recompile__?, do: unquote(changed)
    end
  end
end
