# TwoSites

A Phoenix 1.8 app that serves two websites, each with its own look, routes and pages, from a
single codebase using [multitenancy_phoenix](../../README.md). It is the package's
reference setup and integration test bed. It depends on the package through
`{:multitenancy_phoenix, path: "../.."}`, so package changes are picked up immediately.

| Host                 | Site    | Served by                                         | What it shows                                                     |
| -------------------- | ------- | ------------------------------------------------- | ----------------------------------------------------------------- |
| `alpha.localtest.me` | `alpha` | `themes/alpha`                                    | overrides the home template; red brand colour                     |
| `beta.localtest.me`  | `beta`  | `themes/beta`                                     | home falls back to the base template; theme-only `/about` page    |
| `localhost`          | none    | `TwoSitesWeb.Router` (platform)                   | the plain base app, like an admin or API host                     |
| anything else        | none    | `Multitenancy.Plug.ResolveSite` returns a 404     | unknown hosts are rejected                                        |

Both themes also serve `/counter`, a LiveView. `*.localtest.me` resolves to `127.0.0.1`, so no
`/etc/hosts` changes are needed.

## Running

```
mix setup        # deps, base assets and theme assets
mix test         # routing and LiveView tests for every host
mix phx.server
```

Then open http://alpha.localtest.me:4000, http://beta.localtest.me:4000 and
http://localhost:4000.

## How a request is served

```
GET http://beta.localtest.me/about
  │
  ├─ TwoSitesWeb.Endpoint
  │    ├─ Multitenancy.Plug.ResolveSite   host → %Site{slug: "beta", theme: Themes.Beta}
  │    │                                  assigns @current_site and @current_theme
  │    └─ Multitenancy.Plug.Dispatch      calls the site's theme router
  │
  └─ Themes.Beta.Router                   its own pipelines and routes
       └─ Themes.Beta.PageController.about
            └─ Themes.Beta.PageHTML.about inside Themes.Beta.Layouts (root + app)
```

1. **Site resolution.** `lib/two_sites/application.ex` starts `Multitenancy.SiteResolver.YAML`, which
   loads `priv/sites.yml` into memory at boot. `ResolveSite` looks up `conn.host` there. Hosts listed
   in `config :multitenancy_phoenix, platform_hosts: ["localhost"]` skip resolution, and any other
   unknown host gets a 404.
2. **Dispatch.** In `lib/two_sites_web/endpoint.ex`, the usual `plug TwoSitesWeb.Router` is replaced by
   `ResolveSite` and `Dispatch`. Dispatch calls the theme's router, or `TwoSitesWeb.Router` for platform
   hosts. A route that only exists in beta (`/about`) is a 404 on alpha.
3. **Rendering.** Theme controllers render the theme's HTML modules. The theme's router sets the root
   layout (`put_root_layout`), and templates call `<Layouts.app>`, which resolves to the theme's layouts.

## Sites and settings

```yaml
# priv/sites.yml
alpha:
  theme: alpha
  hosts: [alpha.localtest.me]
  settings:
    title: Alpha Daily

beta:
  theme: beta
  hosts: [beta.localtest.me]
```

Every theme has defaults in `themes/<name>/config/settings.yml`, read at compile time. A site's
`settings` are deep merged on top of them:

| Site  | `title`                                     | `tagline`                                 |
| ----- | ------------------------------------------- | ----------------------------------------- |
| alpha | `Alpha Daily` (from `sites.yml`)            | from `themes/alpha/config/settings.yml`   |
| beta  | `Beta` (theme default)                      | from `themes/beta/config/settings.yml`    |

Templates read them through `@current_site.settings["title"]`. Several sites can share one
theme with different settings; just point more entries at the same `theme`.

## Anatomy of a theme

Both themes were created with `mix multitenancy.gen.theme <name>` and then customised.

```
themes/beta/
  lib/beta.ex                        Themes.Beta: theme definition + `use Themes.Beta, :html | :controller | ...`
  lib/beta/router.ex                 Themes.Beta.Router: pipelines and routes of this site
  lib/beta/layouts.ex                Themes.Beta.Layouts.app/1 (header, nav)
  lib/beta/layouts/root.html.heex    <html>, <head>, links /themes/beta/app.css and app.js
  lib/beta/page_controller.ex        :home and :about actions
  lib/beta/page_html.ex              embed_theme_templates "page_html/*", base: TwoSitesWeb.PageHTML
  lib/beta/page_html/about.html.heex theme-only template (no home: it falls back)
  lib/beta/counter_live.ex           LiveView, mounted in a live_session with Multitenancy.LiveView
  lib/beta/gettext.ex                gettext backend reading themes/beta/priv/gettext
  assets/css/app.css                 imports the base CSS + theme tokens
  assets/js/app.js                   imports the base JS
  config/settings.yml                default settings
```

`Themes.Beta` plays the role `TwoSitesWeb` plays for the base app. Inside the theme, `~p` checks
paths against `Themes.Beta.Router`, `Layouts` means `Themes.Beta.Layouts`, and `gettext` uses
`Themes.Beta.Gettext`. The base `TwoSitesWeb.CoreComponents` is still imported, so components are shared.

`mix.exs` compiles the themes with the rest of the app:

```elixir
defp elixirc_paths(_), do: ["lib" | themes_paths()]
defp themes_paths, do: Path.wildcard("themes/*/lib")
```

## Template fallback

`Themes.Alpha.PageHTML` and `Themes.Beta.PageHTML` both declare:

```elixir
embed_theme_templates "page_html/*", base: TwoSitesWeb.PageHTML
```

- **alpha** has `themes/alpha/lib/alpha/page_html/home.html.heex`, so its own home wins.
- **beta** has no `home.html.heex`, so the base
  `lib/two_sites_web/controllers/page_html/home.html.heex` is compiled **into
  `Themes.Beta.PageHTML`**. The base template calls `<Layouts.app>`, which inside beta means
  `Themes.Beta.Layouts.app`. That's why beta's home shows beta's header, nav and colours, and
  "Rendered by the beta theme".
- The `localhost` platform host renders the same base template with the base layout.

Adding or deleting a file in a theme's `page_html/` recompiles that module, so overrides appear
and disappear without restarting (`mix phx.server` reloads code on request).

## LiveView

`/counter` is defined per theme inside a `live_session`:

```elixir
live_session :beta, on_mount: [Multitenancy.LiveView] do
  live "/counter", CounterLive
end
```

The `Multitenancy.LiveView` hook resolves the site from the socket host on both the HTTP render
and the websocket mount, so `@current_site` is available in `mount/3` and `render/1`. The
connected socket keeps using `Themes.Beta.Router`, so `<.link navigate={~p"/about"}>` stays inside
the theme.

In production, set the endpoint `check_origin` to the list of site hosts. Dev uses
`check_origin: false`.

## Assets

| Source                              | Built to                                  | Built by                            |
| ----------------------------------- | ----------------------------------------- | ----------------------------------- |
| `assets/css/app.css`, `assets/js/app.js` | `priv/static/assets/{css,js}/app.*`  | stock `tailwind` / `esbuild` profiles |
| `themes/<t>/assets/css/app.css`     | `priv/static/themes/<t>/app.css`          | `mix multitenancy.assets`           |
| `themes/<t>/assets/js/app.js`       | `priv/static/themes/<t>/app.js`           | `mix multitenancy.assets`           |

- Each theme's CSS `@import`s the base `assets/css/app.css` (tailwind, daisyUI, heroicons). It adds
  `@source "../../lib"` so tailwind scans the theme's templates, and sets its own `@theme` tokens
  (`--color-brand`, used as `bg-brand` and `text-brand`).
- Each theme's JS imports the base `assets/js/app.js` (LiveSocket, hooks, topbar).
- `config/dev.exs` runs `{Mix.Tasks.Multitenancy.Assets, :run, [~w(--watch)]}` as an endpoint
  watcher, and `live_reload` watches `themes/**/lib` files.
- `mix assets.deploy` builds everything minified, then runs `phx.digest`.
- `"themes"` is in `TwoSitesWeb.static_paths/0`, so `Plug.Static` serves `/themes/**`.

## Tests

`test/two_sites_web/sites/` covers each host:

- `routing_test.exs`:
  - alpha override, beta fallback in beta's layout, beta-only `/about`
  - 404 for `/about` on alpha
  - the platform host
  - unknown hosts
- `counter_live_test.exs`:
  - LiveView mount and click on both hosts
  - `navigate` from `/counter` to `/about` on beta

Requests target a site by setting the host: `get(%{conn | host: "beta.localtest.me"}, "/")`.

## Things to try

- **Override beta's home:** create `themes/beta/lib/beta/page_html/home.html.heex`, then reload
  http://beta.localtest.me:4000.
- **Add a site on an existing theme:** add a `gamma:` entry to `priv/sites.yml` with
  `theme: alpha` and `hosts: [gamma.localtest.me]`, plus its own `settings: {title: Gamma}`, then
  restart the server.
- **Add a theme:** run `mix multitenancy.gen.theme gamma`, point a site at it in
  `priv/sites.yml`, then run `mix multitenancy.assets gamma`.
