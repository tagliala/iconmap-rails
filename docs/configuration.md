# Configuration

`config/iconmap.rb` is intentionally simple — it is a list of `pin` lines. Example:

```ruby
pin '@fortawesome/fontawesome-free/svgs/brands/github.svg' # @6.7.2
pin 'some-package/icons/logo.svg'
```

Engine configuration (programmatic):

```ruby
# config/application.rb
config.iconmap.paths << Rails.root.join('config/iconmap.rb')
config.iconmap.sweep_cache = true
config.iconmap.cache_sweepers << Rails.root.join('vendor/icons')
```

You can add extra `config.iconmap.paths` entries from engines so their pins are merged into the main application.

Programmatic configuration keys (defaults set by the engine):

```ruby
# config/application.rb
config.iconmap.paths        # => Array<Pathname] paths to load pins from
config.iconmap.sweep_cache  # => Boolean whether to enable file watching (defaults to Rails.env.local?)
config.iconmap.cache_sweepers # => Array<Pathname> extra directories to watch for changes
```
