# API Reference

Iconmap exposes a small runtime API via `Rails.application.iconmap`.

```ruby
iconmap = Rails.application.iconmap
iconmap.packages # => Hash of pin name => MappedFile
```

The `Map` is intentionally minimal. The gem expects the developer to drive changes through the CLI rather than manipulating the map programmatically.
