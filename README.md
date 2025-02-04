# Iconmap for Rails

Like [Importmap Rails](https://github.com/rails/importmap-rails), but for Icons.

## Installation

Iconmap for Rails is automatically included in Rails 7+ for new applications, but you can also install it manually in existing applications:

1. Run `./bin/bundle add iconmap-rails`
2. Run `./bin/rails iconmap:install`

You can pin those libraries manually by relying on the compiled versions included in Rails like this:

```ruby
pin "@rails/actioncable", to: "actioncable.esm.js"
pin "@rails/activestorage", to: "activestorage.esm.js"
pin "@rails/actiontext", to: "actiontext.esm.js"
pin "trix"
```

## How do iconmaps work?

At their core, iconmaps are essentially a string substitution for what are referred to as "bare module specifiers". A "bare module specifier" looks like this: `import React from "react"`. This is not compatible with the ES Module loader spec. Instead, to be ESM compatible, you must provide 1 of the 3 following types of specifiers:

- Absolute path:
```js
import React from "/Users/DHH/projects/basecamp/node_modules/react"
```

- Relative path:
```js
import React from "./node_modules/react"
```

- HTTP path:
```js
import React from "https://ga.jspm.io/npm:react@17.0.1/index.js"
```

Iconmap-rails provides a clean API for mapping "bare module specifiers" like `"react"`
to 1 of the 3 viable ways of loading ES Module javascript packages.

For example:

```rb
# config/iconmap.rb
pin "react", to: "https://ga.jspm.io/npm:react@17.0.2/index.js"
```

means "everytime you see `import React from "react"`
change it to `import React from "https://ga.jspm.io/npm:react@17.0.2/index.js"`"

```js
import React from "react"
// => import React from "https://ga.jspm.io/npm:react@17.0.2/index.js"
```

## Usage

The icon map is setup through `Rails.application.iconmap` via the configuration in `config/iconmap.rb`. This file is automatically reloaded in development upon changes, but note that you must restart the server if you remove pins and need them gone from the rendered iconmap or list of preloads.

It makes sense to use logical names that match the package names used by npm, such that if you later want to start transpiling or bundling your code, you won't have to change any module imports.

### Local modules

If you want to import local js module files from `app/javascript/src` or other sub-folders of `app/javascript` (such as `channels`), you must pin these to be able to import them. You can use `pin_all_from` to pick all files in a specific folder, so you don't have to `pin` each module individually.

```rb
# config/iconmap.rb
pin_all_from 'app/javascript/src', under: 'src', to: 'src'
```

The `:to` parameter is only required if you want to change the destination logical import name. If you drop the :to option, you must place the :under option directly after the first parameter.

Allows you to:

```js
// app/javascript/application.js
import { ExampleFunction } from 'src/example_function'
```
Which imports the function from `app/javascript/src/example_function.js`.

Note: Sprockets used to serve assets (albeit without filename digests) it couldn't find from the `app/javascripts` folder with logical relative paths, meaning pinning local files wasn't needed. Propshaft doesn't have this fallback, so when you use Propshaft you have to pin your local modules.

## Using npm packages via JavaScript CDNs

Iconmap for Rails downloads and vendors your npm package dependencies via JavaScript CDNs that provide pre-compiled distribution versions.

You can use the `./bin/iconmap` command that's added as part of the install to pin, unpin, or update npm packages in your import map. This command uses an API from [JSPM.org](https://jspm.org) to resolve your package dependencies efficiently, and then add the pins to your `config/iconmap.rb` file. It can resolve these dependencies from JSPM itself, but also from other CDNs, like [unpkg.com](https://unpkg.com) and [jsdelivr.com](https://www.jsdelivr.com).

```bash
./bin/iconmap pin react
Pinning "react" to vendor/react.js via download from https://ga.jspm.io/npm:react@17.0.2/index.js
Pinning "object-assign" to vendor/object-assign.js via download from https://ga.jspm.io/npm:object-assign@4.1.1/index.js
```

This will produce pins in your `config/iconmap.rb` like so:

```ruby
pin "react" # https://ga.jspm.io/npm:react@17.0.2/index.js
pin "object-assign" # https://ga.jspm.io/npm:object-assign@4.1.1/index.js
```

The packages are downloaded to `vendor/icons`, which you can check into your source control, and they'll be available through your application's own asset pipeline serving.

If you later wish to remove a downloaded pin:

```bash
./bin/iconmap unpin react
Unpinning and removing "react"
Unpinning and removing "object-assign"
```

## Preloading pinned modules

To avoid the waterfall effect where the browser has to load one file after another before it can get to the deepest nested import, iconmap-rails uses [modulepreload links](https://developers.google.com/web/updates/2017/12/modulepreload) by default. If you don't want to preload a dependency, because you want to load it on-demand for efficiency, append `preload: false` to the pin.

Example:

```ruby
# config/iconmap.rb
pin "@github/hotkey", to: "@github--hotkey.js" # file lives in vendor/icons/@github--hotkey.js
pin "md5", preload: false # file lives in vendor/javascript/md5.js

# app/views/layouts/application.html.erb
<%= javascript_iconmap_tags %>

# will include the following link before the iconmap is setup:
<link rel="modulepreload" href="/assets/javascript/@github--hotkey.js">
...
```

You can also specify which entry points to preload a particular dependency in by providing `preload:` a string or array of strings.

Example:

```ruby
# config/iconmap.rb
pin "@github/hotkey", to: "@github--hotkey.js", preload: 'application'
pin "md5", preload: ['application', 'alternate']

# app/views/layouts/application.html.erb
<%= javascript_iconmap_tags 'alternate' %>

# will include the following link before the iconmap is setup:
<link rel="modulepreload" href="/assets/javascript/md5.js">
...
```



## Composing import maps

By default, Rails loads import map definition from the application's `config/iconmap.rb` to the `Iconmap::Map` object available at `Rails.application.iconmap`.

You can combine multiple import maps by adding paths to additional import map configs to `Rails.application.config.iconmap.paths`. For example, appending import maps defined in Rails engines:

```ruby
# my_engine/lib/my_engine/engine.rb

module MyEngine
  class Engine < ::Rails::Engine
    # ...
    initializer "my-engine.iconmap", before: "iconmap" do |app|
      app.config.iconmap.paths << Engine.root.join("config/iconmap.rb")
      # ...
    end
  end
end
```

And pinning JavaScript modules from the engine:

```ruby
# my_engine/config/iconmap.rb

pin_all_from File.expand_path("../app/assets/javascripts", __dir__)
```


## Selectively importing modules

You can selectively import your javascript modules on specific pages.

Create your javascript in `app/javascript`:

```js
// /app/javascript/checkout.js
// some checkout specific js
```

Pin your js file:

```rb
# config/iconmap.rb
# ... other pins...
pin "checkout", preload: false
```

Import your module on the specific page. Note: you'll likely want to use a `content_for` block on the specifc page/partial, then yield it in your layout.

```erb
<% content_for :head do %>
  <%= javascript_import_module_tag "checkout" %>
<% end %>
```

**Important**: The `javascript_import_module_tag` should come after your `javascript_iconmap_tags`

```erb
<%= javascript_iconmap_tags %>
<%= yield(:head) %>
```


## Include a digest of the import map in your ETag

If you're using [ETags](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag) generated by Rails helpers like `stale?` or `fresh_when`, you need to include the digest of the import map into this calculation. Otherwise your application will return [304](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/304) cache responses even when your JavaScript assets have changed. You can avoid this using the `stale_when_iconmap_changes` method:

```ruby
class ApplicationController < ActionController::Base
  stale_when_iconmap_changes
end
```

This will add the digest of the iconmap to the etag calculation when the request format is HTML.


## Sweeping the cache in development and test

Generating the import map json and modulepreloads may require resolving hundreds of assets. This can take a while, so these operations are cached, but in development and test, we watch for changes to both `config/iconmap.rb` and files in `app/javascript` to clear this cache. This feature can be controlled in an environment configuration file via the boolean `config.iconmap.sweep_cache`.

If you're pinning local files from outside of `app/javascript`, you'll need to add them to the cache sweeper configuration or restart your development server upon changes to those external files. For example, here's how you can do it for Rails engine:

```ruby
# my_engine/lib/my_engine/engine.rb

module MyEngine
  class Engine < ::Rails::Engine
    # ...
    initializer "my-engine.iconmap", before: "iconmap" do |app|
      # ...
      app.config.iconmap.cache_sweepers << Engine.root.join("app/assets/icons")
    end
  end
end
```

## Checking for outdated or vulnerable packages

Iconmap for Rails provides two commands to check your pinned packages:
- `./bin/iconmap outdated` checks the NPM registry for new versions
- `./bin/iconmap audit` checks the NPM registry for known security issues

## Supporting legacy browsers such as Safari on iOS 15

If you want to support [legacy browsers that do not support import maps](https://caniuse.com/import-maps) such as [iOS 15.8.1 released on 22 Jan 2024](https://support.apple.com/en-us/HT201222), insert [`es-module-shims`](https://github.com/guybedford/es-module-shims) before `javascript_iconmap_tags` as below.

```erb
<script async src="https://ga.jspm.io/npm:es-module-shims@1.8.2/dist/es-module-shims.js" data-turbo-track="reload"></script>
<%= javascript_iconmap_tags %>
```

## License

Iconmap for Rails is released under the [MIT License](https://opensource.org/licenses/MIT).
