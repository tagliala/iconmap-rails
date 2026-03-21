# Examples

This page collects short, copy-pasteable examples for common tasks.

Font Awesome — GitHub brand SVG

1. Pin the latest version

```bash
./bin/iconmap pin @fortawesome/fontawesome-free/svgs/brands/github.svg
```

2. Pin a specific version (example: 6.7.0)

```bash
./bin/iconmap pin @fortawesome/fontawesome-free@6.7.0/svgs/brands/github.svg
```

Resulting pin in `config/iconmap.rb` (example):

```ruby
pin '@fortawesome/fontawesome-free/svgs/brands/github.svg' # @6.7.0
```

Vendored filename written to `vendor/icons/`:

```
@fortawesome--fontawesome-free--svgs--brands--github.svg
```

Rendering examples

Inline (recommended) with the `inline_svg` gem:

```erb
<%= inline_svg_tag '@fortawesome--fontawesome-free--svgs--brands--github.svg', class: 'icon' %>
```

Via asset helpers:

```ruby
image_tag asset_path('@fortawesome--fontawesome-free--svgs--brands--github.svg'), alt: 'GitHub'
```

Notes

- If jsdelivr cannot resolve a version when pinning without `@<version>`, the CLI will print an error and you can re-run the pin with a specific version.
- Committing `vendor/icons/` to your repo avoids needing to run `./bin/iconmap pristine` on CI.
