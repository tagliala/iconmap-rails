# API Reference

Iconmap exposes a small runtime API via `Rails.application.iconmap`.

```ruby
iconmap = Rails.application.iconmap
iconmap.packages # => Hash of pin name => MappedFile
```

The `Map` is intentionally minimal. The gem expects the developer to drive changes through the CLI rather than manipulating the map programmatically.

Additional notes:

- `Rails.application.iconmap` is initialized by the engine during application boot and loads pins from all paths in `config.iconmap.paths`.
- `iconmap.packages` returns a Hash where each key is the pin string and the value is a small `MappedFile`-like struct with metadata (resolved version, path to vendored file, etc.).
- For most use-cases prefer referencing vendored files via Rails asset helpers rather than interacting with the map directly.
