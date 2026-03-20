# Iconmap for Rails

Manage SVG icons in Rails by vendoring them from npm packages via the [jsdelivr CDN](https://www.jsdelivr.com).

## Installation

1. Run `./bin/bundle add iconmap-rails`
2. Run `./bin/rails iconmap:install`

This creates:

- `config/iconmap.rb` — your icon map configuration
- `vendor/icons/` — where vendored SVG files are stored
- `bin/iconmap` — CLI for managing icons

## How it works

Iconmap for Rails downloads SVG icons from npm packages via the jsdelivr CDN and vendors them locally. Icons are pinned by their npm package path and served through your application's asset pipeline (Sprockets or Propshaft).

A pin in `config/iconmap.rb` looks like:

```ruby
pin '@fortawesome/fontawesome-free/svgs/brands/github.svg' # @6.7.2
```

The SVG file is downloaded and stored as a flat file in `vendor/icons/` (e.g. `@fortawesome--fontawesome-free--svgs--brands--github.svg`), ready to be served by the asset pipeline.

## Usage

### Pinning icons

Use the `bin/iconmap` CLI to pin icons from any npm package that contains SVGs:

```bash
./bin/iconmap pin @fortawesome/fontawesome-free/svgs/brands/github.svg
```

You can pin a specific version:

```bash
./bin/iconmap pin @fortawesome/fontawesome-free@6.7.0/svgs/brands/github.svg
```

Pin multiple icons at once:

```bash
./bin/iconmap pin @fortawesome/fontawesome-free/svgs/brands/github.svg @fortawesome/fontawesome-free/svgs/solid/heart.svg
```

### Unpinning icons

```bash
./bin/iconmap unpin @fortawesome/fontawesome-free/svgs/brands/github.svg
```

This removes the pin from `config/iconmap.rb` and deletes the vendored file.

### Checking for outdated icons

```bash
./bin/iconmap outdated
```

Checks jsdelivr for newer versions of your pinned packages.

### Updating outdated icons

```bash
./bin/iconmap update
```

Re-downloads all icons from packages that have newer versions available.

### Re-downloading all icons

```bash
./bin/iconmap pristine
```

Re-downloads every pinned icon from jsdelivr. Useful after checking out a branch or resolving corrupted vendored files.

### Security audit

```bash
./bin/iconmap audit
```

Checks the npm registry for known security vulnerabilities in your pinned packages.

### Listing pinned packages

```bash
./bin/iconmap packages
```

## Composing icon maps

By default, Rails loads the icon map from `config/iconmap.rb` into `Rails.application.iconmap`.

You can combine multiple icon maps by adding paths to `Rails.application.config.iconmap.paths`, e.g. from a Rails engine:

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

## License

Iconmap for Rails is released under the [MIT License](https://opensource.org/licenses/MIT).
