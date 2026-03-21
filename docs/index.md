# Iconmap for Rails


Iconmap downloads single SVG files from npm packages via the jsdelivr CDN and stores them in `vendor/icons/`. Pins live in `config/iconmap.rb` so your application can reference a stable, versioned copy of each icon.

Quick facts:

- CDN: jsdelivr (https://www.jsdelivr.com)
- Vendored files: `vendor/icons/` (flat filenames derived from pin paths)
- Pin file: `config/iconmap.rb` (a list of `pin '<package>/<path>'` lines)
- Runtime API: `Rails.application.iconmap`

See the Installation and CLI docs for common tasks (pin, unpin, update, pristine, audit).

Example — Font Awesome GitHub icon

```bash
# pin the latest
./bin/iconmap pin @fortawesome/fontawesome-free/svgs/brands/github.svg

# pin a specific version
./bin/iconmap pin @fortawesome/fontawesome-free@6.7.0/svgs/brands/github.svg
```

After pinning, the vendored file will be available in `vendor/icons/` with a flattened filename such as:

```
@fortawesome--fontawesome-free--svgs--brands--github.svg
```

Recommended: render the SVG inline using the `inline_svg` gem:

```erb
<%= inline_svg_tag '@fortawesome--fontawesome-free--svgs--brands--github.svg', class: 'icon' %>
```
