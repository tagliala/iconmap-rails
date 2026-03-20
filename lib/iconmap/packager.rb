# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require_relative 'jsdelivr'

class Iconmap::Packager
  Error        = Class.new(StandardError)
  HTTPError    = Class.new(Error)

  attr_reader :vendor_path

  def initialize(iconmap_path = 'config/iconmap.rb', vendor_path: 'vendor/icons')
    @iconmap_path = Pathname.new(iconmap_path)
    @vendor_path  = Pathname.new(vendor_path)
  end

  # Parse an icon argument like "@fortawesome/fontawesome-free@7.0.0/svgs/brands/github.svg"
  # into { package:, path:, version: }
  def parse_icon_path(arg)
    if arg.start_with?('@')
      # Scoped package: @scope/name@version/path or @scope/name/path
      scope_and_rest = arg[1..] # remove leading @
      parts = scope_and_rest.split('/', 3)
      scope = parts[0]
      name_with_maybe_version = parts[1]
      remainder = parts[2]

      if name_with_maybe_version.include?('@')
        name, version = name_with_maybe_version.split('@', 2)
      else
        name = name_with_maybe_version
        version = nil
      end

      { package: "@#{scope}/#{name}", path: remainder, version: version }
    else
      # Unscoped package: name@version/path or name/path
      parts = arg.split('/', 2)
      name_with_maybe_version = parts[0]
      remainder = parts[1]

      if name_with_maybe_version.include?('@')
        name, version = name_with_maybe_version.split('@', 2)
      else
        name = name_with_maybe_version
        version = nil
      end

      { package: name, path: remainder, version: version }
    end
  end

  def pin(arg)
    parsed = parse_icon_path(arg)
    version = parsed[:version] || jsdelivr.resolve_version(parsed[:package])

    raise Error, "Could not resolve version for #{parsed[:package]}" unless version

    url = jsdelivr.download_url(parsed[:package], version, parsed[:path])
    download(parsed[:package], version, parsed[:path], url)
    vendored_pin_for(parsed[:package], parsed[:path], version)
  end

  def vendored_pin_for(package, path, version)
    %(pin '#{package}/#{path}' # @#{version})
  end

  def packaged?(package_with_path)
    iconmap.match(/^pin ['"]#{Regexp.escape(package_with_path)}['"].*$/)
  end

  def download(package, version, path, url = nil)
    url ||= jsdelivr.download_url(package, version, path)
    ensure_vendor_directory_exists
    remove_existing_vendored_file(package, path)
    content = jsdelivr.fetch_file(url)
    save_vendored_file(package, path, version, url, content)
  end

  def remove(package_with_path)
    parsed = parse_icon_path(package_with_path)
    remove_existing_vendored_file(parsed[:package], parsed[:path])
    remove_package_from_iconmap(package_with_path)
  end

  def vendored_package_path(package, path)
    @vendor_path.join(vendored_filename(package, path))
  end

  def vendored_filename(package, path)
    "#{package}/#{path}".gsub('/', '--')
  end

  private

  def jsdelivr
    @jsdelivr ||= Iconmap::Jsdelivr.new
  end

  def iconmap
    @iconmap ||= File.read(@iconmap_path)
  end

  def ensure_vendor_directory_exists
    FileUtils.mkdir_p @vendor_path
  end

  def remove_existing_vendored_file(package, path)
    FileUtils.rm_f vendored_package_path(package, path)
  end

  def remove_package_from_iconmap(package_with_path)
    all_lines = File.readlines(@iconmap_path)
    with_lines_removed = all_lines.grep_v(/pin ['"]#{Regexp.escape(package_with_path)}['"]/)

    File.open(@iconmap_path, 'w') do |file|
      with_lines_removed.each { |line| file.write(line) }
    end
  end

  def save_vendored_file(package, path, version, url, content)
    File.open(vendored_package_path(package, path), 'w+') do |file|
      file.write "<!-- #{package}/#{path}@#{version} downloaded from #{url} -->\n\n"
      file.write content
    end
  end
end
