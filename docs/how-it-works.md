# How it works

Iconmap is intentionally narrow in scope: it handles vendoring of SVG icons from npm packages and serving them from the Rails app. If you use importmap-rails for JavaScript, Iconmap complements it by handling SVG assets.


Flow when pinning an icon:

1. The CLI receives one or more pin arguments (example: `@fortawesome/fontawesome-free/svgs/brands/github.svg`).
2. The packager parses the npm package name, optional `@version`, and the path to the SVG inside the package.
3. When no explicit version is provided, the packager queries jsdelivr's data API to resolve the latest published version.
4. The SVG is fetched from `https://cdn.jsdelivr.net/npm/<package>@<version>/<path>` and saved to `vendor/icons/` using a flat filename (slashes replaced by `--`).
5. `config/iconmap.rb` is updated: pins for newly vendored icons are added or existing pin lines are annotated with `# @<version>`.

Failures and edge-cases:

- If jsdelivr cannot resolve a version the CLI prints an error and leaves the pin without a version comment; you can retry later with a specific `@version`.
- If multiple pins reference the same npm package but different paths, each pin is handled independently and results in a separate vendored file.

Serving:

- `vendor/icons/` is added to the asset pipeline paths so you can reference the vendored SVGs with normal Rails asset helpers.

Cache sweeping:

- In local environments Iconmap configures a file watcher to clear its map cache when `config/iconmap.rb` or the watched vendor directories change.
