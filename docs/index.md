# Iconmap for Rails


Iconmap downloads single SVG files from npm packages via the jsdelivr CDN and stores them in `vendor/icons/`. Pins are stored in `config/iconmap.rb` so your application can reference a stable, versioned copy of each icon.

- Downloads icons from CDN: jsdelivr
- Stores files in: `vendor/icons/`
- Tracks pins in: `config/iconmap.rb`
- Integrates with Rails: `Rails.application.iconmap`

See the Installation and Guide sections for full usage.
