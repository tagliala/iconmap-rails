# Iconmap for Rails


Iconmap downloads single SVG files from npm packages via the jsdelivr CDN and stores them in `vendor/icons/`. Pins live in `config/iconmap.rb` so your application can reference a stable, versioned copy of each icon.

Quick facts:

- CDN: jsdelivr (https://www.jsdelivr.com)
- Vendored files: `vendor/icons/` (flat filenames derived from pin paths)
- Pin file: `config/iconmap.rb` (a list of `pin '<package>/<path>'` lines)
- Runtime API: `Rails.application.iconmap`

See the Installation and CLI docs for common tasks (pin, unpin, update, pristine, audit).
