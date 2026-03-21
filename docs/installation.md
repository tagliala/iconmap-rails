# Installation

1. Add the gem:

```bash
./bin/bundle add iconmap-rails
```

2. Run the installer generator which creates `config/iconmap.rb`, `vendor/icons/`, and a `bin/iconmap` binstub:

```bash
./bin/rails iconmap:install
```

The binstub is copied from the gem's install template and invokes the CLI commands that manage pins and vendored assets.
