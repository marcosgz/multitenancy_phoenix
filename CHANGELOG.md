# Changelog

## 0.3.0

- Add `Multitenancy.compiled_theme_names/1`, which lists the themes compiled into an app from its loaded modules. Unlike `theme_names/1`, which scans `themes/*/lib`, it also works in a release, where the source tree isn't shipped.

## 0.2.0

- Add site data, `resolve_conn/1`, platform paths and esbuild args.

## 0.1.0

- Initial release.
