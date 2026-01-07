# frozen_string_literal: true

require 'thor'
require_relative 'packager'
require_relative 'npm'

class Iconmap::Commands < Thor
  include Thor::Actions

  def self.exit_on_failure?
    false
  end

  desc 'pin [*PACKAGES]', 'Pin new icons'
  option :env, type: :string, aliases: :e, default: 'production'
  option :from, type: :string, aliases: :f, default: 'jspm'
  def pin(*packages)
    for_each_import(packages, env: options[:env], from: options[:from]) do |package, url|
      pin_package(package, url, options[:from], options[:preload])
    end
  end

  desc 'unpin [*PACKAGES]', 'Unpin existing packages'
  option :env, type: :string, aliases: :e, default: 'production'
  def unpin(*packages)
    for_each_import(packages, env: options[:env], from: '') do |package, _url|
      if packager.packaged?(package)
        puts %(Unpinning and removing "#{package}")
        packager.remove(package)
      end
    end
  end

  desc 'pristine', 'Redownload all pinned packages'
  option :env, type: :string, aliases: :e, default: 'production'
  def pristine
    packages = prepare_packages_with_versions

    packages.each do |package, package_options|
      for_each_import(package, env: options[:env], from: package_options[:from]) do |package, url|
        puts %(Downloading "#{package}" to #{packager.vendor_path}/#{package} from #{url})

        packager.download(package, url)
      end
    end
  end

  desc 'json', 'Show the full iconmap in json'
  def json
    require Rails.root.join('config/environment')
    puts Rails.application.iconmap.to_json(resolver: ActionController::Base.helpers)
  end

  desc 'audit', 'Run a security audit'
  def audit
    vulnerable_packages = npm.vulnerable_packages

    if vulnerable_packages.any?
      table = [['Icon', 'Severity', 'Vulnerable versions', 'Vulnerability']]
      vulnerable_packages.each { |p| table << [p.name, p.severity, p.vulnerable_versions, p.vulnerability] }

      puts_table(table)
      vulnerabilities = 'vulnerability'.pluralize(vulnerable_packages.size)
      severities = vulnerable_packages.map(&:severity).tally.sort_by(&:last).reverse
                                      .map { |severity, count| "#{count} #{severity}" }
                                      .join(', ')
      puts "  #{vulnerable_packages.size} #{vulnerabilities} found: #{severities}"

      exit 1
    else
      puts 'No vulnerable icons found'
    end
  end

  desc 'outdated', 'Check for outdated icons'
  def outdated
    if (outdated_packages = npm.outdated_packages).any?
      table = [%w[Icon Current Latest]]
      outdated_packages.each { |p| table << [p.name, p.current_version, p.latest_version || p.error] }

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
      package_names = outdated_packages.map(&:name)
      packages_with_options = packager.extract_existing_pin_options(package_names)

      package_names.each do |package_name|
        options = packages_with_options[package_name] || {}

        for_each_import(package_name, env: 'production', from: options[:from]) do |package, url|
          pin_package(package, url, options[:from], options[:preload])
        end
      end
    else
      puts 'No outdated icons found'
    end
  end

  desc 'packages', 'Print out icons with version numbers'
  def packages
    puts(npm.packages_with_versions.map { |x| x.join(' ') })
  end

  private

  def packager
    @packager ||= Iconmap::Packager.new
  end

  def npm
    @npm ||= Iconmap::Npm.new
  end

  def pin_package(package, url, from, preload)
    puts %(Pinning "#{package}" to #{packager.vendor_path}/#{package}.js via download from #{url})

    packager.download(package, url)

    pin = packager.vendored_pin_for(package, url, from, preload)

    update_importmap_with_pin(package, pin)
  end

  def update_importmap_with_pin(package, pin)
    new_pin = "#{pin}\n"

    if packager.packaged?(package)
      gsub_file('config/iconmap.rb', Iconmap::Map.pin_line_regexp_for(package), new_pin, verbose: false)
    else
      append_to_file('config/iconmap.rb', new_pin, verbose: false)
    end
  end

  def handle_package_not_found(packages, from)
    puts "Couldn't find any icons in #{packages.inspect} on #{from}"
  end

  def remove_line_from_file(path, pattern)
    path = File.expand_path(path, destination_root)

    all_lines = File.readlines(path)
    with_lines_removed = all_lines.select { |line| line !~ pattern }

    File.open(path, 'w') do |file|
      with_lines_removed.each { |line| file.write(line) }
    end
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

  def prepare_packages_with_versions(packages = [])
    if packages.empty?
      npm_packages_with_versions = npm.packages_with_versions
      packages_with_options = packager.extract_existing_pin_options(npm_packages_with_versions.map(&:first))

      npm_packages_with_versions.to_h do |p, v|
        options = packages_with_options[p]
        if v.blank?
          [p, options]
        elsif p.start_with?('@')
          parts = p.split('/', 3)
          ["#{parts[0..1].join('/')}@#{v}/#{parts[2]}", options]
        else
          parts = p.split('/', 2)
          ["#{parts[0]}@#{v}/#{parts[1]}", options]
        end
      end
    else
      packages
    end
  end

  def for_each_import(packages, **options, &)
    response = packager.import(*packages, **options)

    if response
      response[:imports].each(&)
    else
      handle_package_not_found(packages, options[:from])
    end
  end
end

Iconmap::Commands.start(ARGV)
