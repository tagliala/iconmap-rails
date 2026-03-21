# frozen_string_literal: true

require 'thor'
require 'active_support/core_ext/string/inflections'
require_relative 'packager'
require_relative 'npm'

class Iconmap::Commands < Thor
  include Thor::Actions

  def self.exit_on_failure?
    false
  end

  desc 'pin [*PACKAGES]', 'Pin new icons'
  def pin(*packages)
    packages.each do |package|
      pin_line = packager.pin(package)
      parsed = packager.parse_icon_path(package)
      package_with_path = "#{parsed[:package]}/#{parsed[:path]}"

      puts %(Pinning "#{package_with_path}" to #{packager.vendor_path}/#{packager.vendored_filename(parsed[:package], parsed[:path])})

      if packager.packaged?(package_with_path)
        gsub_file('config/iconmap.rb', /^pin ['"]#{Regexp.escape(package_with_path)}['"].*$/, pin_line, verbose: false)
      else
        append_to_file('config/iconmap.rb', "#{pin_line}\n", verbose: false)
      end
    end
  end

  desc 'unpin [*PACKAGES]', 'Unpin existing packages'
  def unpin(*packages)
    packages.each do |package|
      parsed = packager.parse_icon_path(package)
      package_with_path = "#{parsed[:package]}/#{parsed[:path]}"

      if packager.packaged?(package_with_path)
        puts %(Unpinning and removing "#{package_with_path}")
        packager.remove(package_with_path)
      end
    end
  end

  desc 'pristine', 'Redownload all pinned icons'
  def pristine
    npm.packages_with_versions.each do |package, version|
      # Find all pins for this package to get full paths
      iconmap_content = File.read('config/iconmap.rb')
      iconmap_content.scan(%r{^pin ['"]#{Regexp.escape(package)}/([^'"]+)['"].*#\s*@#{Regexp.escape(version)}}).each do |path,|
        package_with_path = "#{package}/#{path}"
        url = Iconmap::Jsdelivr.new.download_url(package, version, path)
        puts %(Downloading "#{package_with_path}" to #{packager.vendor_path}/#{packager.vendored_filename(package, path)} from #{url})
        packager.download(package, version, path, url)
      end
    end
  end

  desc 'audit', 'Run a security audit'
  def audit
    vulnerable_packages = npm.vulnerable_packages

    if vulnerable_packages.any?
      table = [['Package', 'Severity', 'Vulnerable versions', 'Vulnerability']]
      vulnerable_packages.each { |p| table << [p.name, p.severity, p.vulnerable_versions, p.vulnerability] }

      puts_table(table)
      vulnerabilities = 'vulnerability'.pluralize(vulnerable_packages.size)
      severities = vulnerable_packages.map(&:severity).tally.sort_by(&:last).reverse
                                      .map { |severity, count| "#{count} #{severity}" }
                                      .join(', ')
      puts "  #{vulnerable_packages.size} #{vulnerabilities} found: #{severities}"

      exit 1
    else
      puts 'No vulnerable packages found'
    end
  end

  desc 'outdated', 'Check for outdated packages'
  def outdated
    if (outdated_packages = npm.outdated_packages).any?
      table = [%w[Icon Current Latest]]
      outdated_packages.each { |p| table << [p.icon_path, p.current_version, p.latest_version || p.error] }

      puts_table(table)
      packages = 'icon'.pluralize(outdated_packages.size)
      puts "  #{outdated_packages.size} outdated #{packages} found"

      exit 1
    else
      puts 'No outdated icons found'
    end
  end

  desc 'update', 'Update outdated icon pins'
  def update
    if (outdated_packages = npm.outdated_packages).any?
      outdated_packages.each do |pkg|
        pin(pkg.icon_path)
      end
    else
      puts 'No outdated icons found'
    end
  end

  desc 'packages', 'Print out icons with version numbers'
  def packages
    # Print each package only once (multiple pins may reference the same npm package)
    seen = {}
    npm.packages_with_versions.each do |package, version, _|
      seen[package] ||= version
    end

    puts(seen.map { |package, version| "#{package} #{version}" })
  end

  private

  def packager
    @packager ||= Iconmap::Packager.new
  end

  def npm
    @npm ||= Iconmap::Npm.new
  end

  def puts_table(array)
    column_sizes = array.reduce([]) do |lengths, row|
      row.each_with_index.map { |iterand, index| [lengths[index] || 0, iterand.to_s.length].max }
    end

    divider = '|' + column_sizes.map { |s| '-' * (s + 2) }.join('|') + '|'
    array.each_with_index do |row, row_number|
      row = row.fill(nil, row.size..(column_sizes.size - 1))
      row = row.each_with_index.map { |v, i| v.to_s + (' ' * (column_sizes[i] - v.to_s.length)) }
      puts '| ' + row.join(' | ') + ' |'
      puts divider if row_number == 0
    end
  end
end

Iconmap::Commands.start(ARGV)
