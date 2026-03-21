# CLI Reference

All CLI commands are exposed via the `bin/iconmap` binstub added by `iconmap:install`.

## pin

Pin icons (single or multiple):

```bash
./bin/iconmap pin @fortawesome/fontawesome-free/svgs/brands/github.svg
```

If you include `@<version>` in the package name, that version is used. Otherwise, Iconmap resolves the latest version via jsdelivr.

Examples:

```bash
./bin/iconmap pin @fortawesome/fontawesome-free/svgs/brands/github.svg
./bin/iconmap pin @fortawesome/fontawesome-free@6.7.0/svgs/brands/github.svg
./bin/iconmap pin some-package/icons/logo.svg another-package/icons/x.svg
```

Real example — Font Awesome GitHub brand icon

```bash
# pin the latest
./bin/iconmap pin @fortawesome/fontawesome-free/svgs/brands/github.svg

# pin a specific version
./bin/iconmap pin @fortawesome/fontawesome-free@6.7.0/svgs/brands/github.svg
```

The vendored file will appear in `vendor/icons/` with a flattened filename, for example:

```
@fortawesome--fontawesome-free--svgs--brands--github.svg
```

Recommended: render the SVG inline using the `inline_svg` gem (https://github.com/jamesmartin/inline_svg):

```erb
<%= inline_svg_tag '@fortawesome--fontawesome-free--svgs--brands--github.svg', class: 'icon' %>
```

Or reference via the asset pipeline:

```ruby
image_tag asset_path('@fortawesome--fontawesome-free--svgs--brands--github.svg'), alt: 'GitHub'
```

## unpin

```bash
./bin/iconmap unpin @fortawesome/fontawesome-free/svgs/brands/github.svg
```

Removes the pin and deletes the vendored file.

Note: `unpin` only removes the vendored SVG matching the pin and the pin line in `config/iconmap.rb`; it does not modify other pins that reference the same npm package.

## outdated

```bash
./bin/iconmap outdated
```

Checks the registry/CDN for newer package versions and prints a table of outdated icons.

Exit codes: 0 when nothing is outdated, 1 when at least one pinned icon is outdated, 2 on fatal errors.

## update

```bash
./bin/iconmap update
```

Updates all outdated pins: downloads new files and updates `config/iconmap.rb`.

You can also update a single pin by passing it explicitly, e.g. `./bin/iconmap update @fortawesome/fontawesome-free/svgs/brands/github.svg`.

## pristine

```bash
./bin/iconmap pristine
```

Re-downloads every pinned icon from the CDN and replaces vendored files.

Useful when vendored files were omitted from source control or when switching branches with different pins.

## audit

```bash
./bin/iconmap audit
```

Performs a security audit against the npm advisories API for the pinned package versions.

The command exits with status 1 if vulnerabilities are found; read the printed table for details on severity and affected versions.

## packages

```bash
./bin/iconmap packages
```

Lists all pinned packages and their pinned versions.

Output format: `<package> <resolved-version> <pin-path>` per line, which makes it easy to parse in scripts.
