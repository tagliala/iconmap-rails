# How it works

Iconmap is intentionally narrow in scope: it handles vendoring of SVG icons from npm packages and serving them from the Rails app. If you use importmap-rails for JavaScript, Iconmap complements it by handling SVG assets.

Flow when pinning an icon:

1. CLI receives the pin (example: `@fortawesome/fontawesome-free/svgs/brands/github.svg`).
2. The Packager parses package name, optional version, and path.
3. If no version was provided, Iconmap queries jsdelivr's data API to resolve the latest package version.
4. The SVG is downloaded from `https://cdn.jsdelivr.net/npm/<package>@<version>/<path>`.
5. The file is saved under `vendor/icons/` with slashes replaced by `--`.
6. A `pin` line with `# @<version>` is appended or updated in `config/iconmap.rb`.

Serving:

- `vendor/icons/` is added to the asset pipeline paths so you can reference the vendored SVGs with normal Rails asset helpers.

Cache sweeping:

- In local environments Iconmap configures a file watcher to clear its map cache when `config/iconmap.rb` or the watched vendor directories change.
