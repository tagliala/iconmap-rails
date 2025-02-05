# frozen_string_literal: true

module Iconmap::IconmapTagsHelper
  # Setup all script tags needed to use an iconmap-powered entrypoint (which defaults to application.js)
  def javascript_iconmap_tags(entry_point = 'application', iconmap: Rails.application.iconmap)
    safe_join [
      javascript_inline_iconmap_tag(iconmap.to_json(resolver: self)),
      javascript_iconmap_module_preload_tags(iconmap, entry_point:),
      javascript_import_module_tag(entry_point)
    ], "\n"
  end

  # Generate an inline iconmap tag using the passed `iconmap_json` JSON string.
  # By default, `Rails.application.iconmap.to_json(resolver: self)` is used.
  def javascript_inline_iconmap_tag(iconmap_json = Rails.application.iconmap.to_json(resolver: self))
    tag.script iconmap_json.html_safe,
               type: 'iconmap', 'data-turbo-track': 'reload', nonce: request&.content_security_policy_nonce
  end

  # Import a named JavaScript module(s) using a script-module tag.
  def javascript_import_module_tag(*module_names)
    imports = Array(module_names).collect { |m| %(import "#{m}") }.join("\n")
    tag.script imports.html_safe, type: 'module', nonce: request&.content_security_policy_nonce
  end

  # Link tags for preloading all modules marked as preload: true in the `iconmap`
  # (defaults to Rails.application.iconmap), such that they'll be fetched
  # in advance by browsers supporting this link type (https://caniuse.com/?search=modulepreload).
  def javascript_iconmap_module_preload_tags(iconmap = Rails.application.iconmap, entry_point: 'application')
    javascript_module_preload_tag(*iconmap.preloaded_module_paths(resolver: self, entry_point:, cache_key: entry_point))
  end

  # Link tag(s) for preloading the JavaScript module residing in `*paths`. Will return one link tag per path element.
  def javascript_module_preload_tag(*paths)
    safe_join(Array(paths).collect do |path|
      tag.link rel: 'modulepreload', href: path, nonce: request&.content_security_policy_nonce
    end, "\n")
  end
end
