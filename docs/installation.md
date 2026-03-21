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

Notes:

- The installer will create `vendor/icons/` if it does not exist; you can commit the directory and vendored SVGs to your repository to avoid requiring the installer on CI.
- The `bin/iconmap` binstub is a thin wrapper; running it from the project root (e.g. `./bin/iconmap pin ...`) is the recommended workflow.
