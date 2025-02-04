say "Use vendor/icons for downloaded pins"
empty_directory "vendor/icons"
keep_file "vendor/icons"

if (sprockets_manifest_path = Rails.root.join("app/assets/config/manifest.js")).exist?
  say "Ensure icons are in the Sprocket manifest"
  append_to_file sprockets_manifest_path,
    %(//= link_tree ../../../vendor/icons .svg\n)
end

say "Configure iconmap paths in config/iconmap.rb"
copy_file "#{__dir__}/config/iconmap.rb", "config/iconmap.rb"

say "Copying binstub"
copy_file "#{__dir__}/bin/iconmap", "bin/iconmap"
chmod "bin", 0755 & ~File.umask, verbose: false
