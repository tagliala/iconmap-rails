# CLI Reference

All CLI commands are exposed via the `bin/iconmap` binstub added by `iconmap:install`.

## pin

Pin icons (single or multiple):

```bash
./bin/iconmap pin @fortawesome/fontawesome-free/svgs/brands/github.svg
```

If you include `@<version>` in the package name, that version is used. Otherwise, Iconmap resolves the latest version via jsdelivr.

## unpin

```bash
./bin/iconmap unpin @fortawesome/fontawesome-free/svgs/brands/github.svg
```

Removes the pin and deletes the vendored file.

## outdated

```bash
./bin/iconmap outdated
```

Checks the registry/CDN for newer package versions and prints a table of outdated icons.

## update

```bash
./bin/iconmap update
```

Updates all outdated pins: downloads new files and updates `config/iconmap.rb`.

## pristine

```bash
./bin/iconmap pristine
```

Re-downloads every pinned icon from the CDN and replaces vendored files.

## audit

```bash
./bin/iconmap audit
```

Performs a security audit against the npm advisories API for the pinned package versions.

## packages

```bash
./bin/iconmap packages
```

Lists all pinned packages and their pinned versions.
