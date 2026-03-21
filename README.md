# Iconmap for Rails

Manage SVG icons from npm packages by vendoring them locally and serving them through the Rails asset pipeline.

Iconmap for Rails downloads individual SVG files from npm packages via the [jsdelivr CDN](https://www.jsdelivr.com) and stores them in your Rails application. Icons are referenced by their npm package path and served as static files through Sprockets or Propshaft.

## Installation

1. Run `./bin/bundle add iconmap-rails`
2. Run `./bin/rails iconmap:install`

This creates:

- `config/iconmap.rb` — your icon map configuration
- `vendor/icons/` — where vendored SVG files are stored
- `bin/iconmap` — CLI for managing icons

## How it works

Iconmap for Rails uses a pin-based system to manage SVG icons from npm packages:

1. **Pin an icon**: When you pin an icon (for example, `@fortawesome/fontawesome-free/svgs/brands/github.svg`), the gem:
   - Parses the package name, optional version, and icon path
   - Resolves the npm package version via the jsdelivr data API (unless you pinned an explicit version)
   - Downloads the SVG from `https://cdn.jsdelivr.net/npm/<package>@<version>/<path>`
   - Saves it to `vendor/icons/` with a flat filename (slashes replaced by `--`)
   - Adds or updates a `pin` line in `config/iconmap.rb` with the resolved version

2. **Serve icons**: The `vendor/icons/` directory is added to the Rails asset paths, so icons are served as normal static assets.

A pin in `config/iconmap.rb` looks like:

```ruby
pin '@fortawesome/fontawesome-free/svgs/brands/github.svg' # @6.7.2
```

The SVG file is downloaded and stored as a flat file in `vendor/icons/` (for example,
`@fortawesome--fontawesome-free--svgs--brands--github.svg`), ready to be served by the asset pipeline.

## Usage

All commands are run via the `bin/iconmap` binstub that `iconmap:install` creates.

### Pinning icons

Pin a single icon from an npm package:

```bash
./bin/iconmap pin @fortawesome/fontawesome-free/svgs/brands/github.svg
```

Pin a specific version:

```bash
./bin/iconmap pin @fortawesome/fontawesome-free@6.7.0/svgs/brands/github.svg
```

Pin multiple icons at once:

```bash
./bin/iconmap pin \
  @fortawesome/fontawesome-free/svgs/brands/github.svg \
  @fortawesome/fontawesome-free/svgs/solid/heart.svg
```

After pinning, you will see lines like this in `config/iconmap.rb`:

```ruby
pin '@fortawesome/fontawesome-free/svgs/brands/github.svg' # @6.7.2
pin '@fortawesome/fontawesome-free/svgs/solid/heart.svg'   # @6.7.2
```

### Unpinning icons

Remove an icon and its vendored file:

```bash
./bin/iconmap unpin @fortawesome/fontawesome-free/svgs/brands/github.svg
```

This removes the matching `pin` line from `config/iconmap.rb` and deletes the vendored SVG file from `vendor/icons/`.

### Checking for outdated icons

Check jsdelivr for newer versions of the npm packages behind your pinned icons:

```bash
./bin/iconmap outdated
```

Example output:

```
| Icon                                                 | Current | Latest |
|------------------------------------------------------|---------|--------|
| @fortawesome/fontawesome-free/svgs/brands/github.svg | 6.7.0   | 6.7.2  |
  1 outdated icon found
```

If jsdelivr fails to resolve a version for a package, the table will show an error message in the `Latest` column.

### Updating outdated icons

Re-download icons from packages that have newer versions available and update your pins:

```bash
./bin/iconmap update
```

For each outdated icon, this command:

- Downloads the SVG for the latest version
- Replaces the vendored file in `vendor/icons/`
- Updates the `# @<version>` comment in `config/iconmap.rb`

### Re-downloading all icons

Re-download every pinned icon from jsdelivr, regardless of version:

```bash
./bin/iconmap pristine
```

This is useful after checking out a new branch, restoring from backup, or when vendored files may be corrupted.

### Security audit

Check the npm registry for known security vulnerabilities in your pinned packages:

```bash
./bin/iconmap audit
```

Example output:

```
| Package        | Severity | Vulnerable versions | Vulnerability        |
|----------------|----------|---------------------|----------------------|
| some-package   | high     | < 2.0.0             | Remote code execution|
  1 vulnerability found: 1 high
```

The command exits with status 1 when vulnerabilities are found.

### Listing pinned packages

Display all pinned icons with their resolved versions:

```bash
./bin/iconmap packages
```

Example output:

```
@fortawesome/fontawesome-free 6.7.2 @fortawesome/fontawesome-free/svgs/brands/github.svg
@fortawesome/fontawesome-free 6.7.2 @fortawesome/fontawesome-free/svgs/solid/heart.svg
```

## Configuration

### config/iconmap.rb

The icon map file uses `pin` directives to define vendored icons:

```ruby
# config/iconmap.rb

# Pin icons by running ./bin/iconmap

# Pin with version comment (automatically added by iconmap)

# Pin without version comment (version will be resolved dynamically)
```

Iconmap does not currently support additional pin options (like `preload:` or `to:`) – every pin represents a single SVG at a specific version.

### Cache sweeping

In development and test environments, Iconmap can automatically clear its internal caches when files change.

The engine configures:

- `config.iconmap.paths` — list of iconmap config files (by default just `config/iconmap.rb`)
- `config.iconmap.sweep_cache` — whether to set up file watching (defaults to `Rails.env.local?`)
- `config.iconmap.cache_sweepers` — extra directories to watch in addition to `vendor/icons`

When any watched file changes, the icon map cache is cleared.

## Composing icon maps

By default, Rails loads the icon map from `config/iconmap.rb` into `Rails.application.iconmap`.

You can combine multiple icon maps by adding paths to `Rails.application.config.iconmap.paths`, for example from a Rails engine:

```ruby
# my_engine/lib/my_engine/engine.rb
module MyEngine
  class Engine < ::Rails::Engine
    initializer 'my-engine.iconmap', before: 'iconmap' do |app|
      app.config.iconmap.paths << Engine.root.join('config/iconmap.rb')
    end
  end
end
```

The engine's `config/iconmap.rb` can then declare its own pins that will be merged into the main application's icon map.

## Rails integration

Iconmap for Rails integrates via a Rails engine (`Iconmap::Engine`) that:

1. **Defines `Rails.application.iconmap`** as an `Iconmap::Map` instance.
2. **Loads pin definitions** from all paths in `config.iconmap.paths` (by default `config/iconmap.rb`).
3. **Adds `vendor/icons` to the asset pipeline** so your SVGs are served like any other asset.
4. **Optionally sets up a cache sweeper** in development and test that watches icon files and clears the map cache when they change.

### Accessing the icon map

```ruby
iconmap = Rails.application.iconmap
iconmap.packages #=> hash of pin name -> MappedFile
```

The `Iconmap::Map` API is intentionally small and internal – most applications should interact with icons via the CLI and asset helpers, not by manipulating the map directly.

## License

Iconmap for Rails is released under the [MIT License](https://opensource.org/licenses/MIT).
