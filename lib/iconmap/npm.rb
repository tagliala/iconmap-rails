# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require_relative 'jsdelivr'

class Iconmap::Npm
  Error     = Class.new(StandardError)
  HTTPError = Class.new(Error)

  singleton_class.attr_accessor :base_uri
  self.base_uri = URI('https://registry.npmjs.org')

  def initialize(iconmap_path = 'config/iconmap.rb')
    @iconmap_path = Pathname.new(iconmap_path)
  end

  def outdated_packages
    packages_with_versions.each.with_object([]) do |(package, current_version), outdated_packages|
      outdated_package = OutdatedPackage.new(name: package, current_version: current_version)

      latest_version = jsdelivr.resolve_version(package)

      if latest_version.nil?
        outdated_package.error = 'Response error'
      elsif outdated?(current_version, latest_version)
        outdated_package.latest_version = latest_version
      else
        next
      end

      outdated_packages << outdated_package
    end.sort_by(&:name)
  end

  def vulnerable_packages
    get_audit.flat_map do |package, vulnerabilities|
      vulnerabilities.map do |vulnerability|
        VulnerablePackage.new(name: package,
                              severity: vulnerability['severity'],
                              vulnerable_versions: vulnerability['vulnerable_versions'],
                              vulnerability: vulnerability['title'])
      end
    end.sort_by { |p| [p.name, p.severity] }
  end

  def packages_with_versions
    iconmap.scan(/^pin ['"]([^'"]+)['"].*#\s*@(\S+)/).map do |package_with_path, version|
      package = extract_package_name(package_with_path)
      [package, version]
    end.uniq
  end

  private

  OutdatedPackage   = Struct.new(:name, :current_version, :latest_version, :error, keyword_init: true)
  VulnerablePackage = Struct.new(:name, :severity, :vulnerable_versions, :vulnerability, keyword_init: true)

  def extract_package_name(package_with_path)
    if package_with_path.start_with?('@')
      parts = package_with_path.split('/', 3)
      "#{parts[0]}/#{parts[1]}"
    else
      package_with_path.split('/', 2).first
    end
  end

  def iconmap
    @iconmap ||= File.read(@iconmap_path)
  end

  def jsdelivr
    @jsdelivr ||= Iconmap::Jsdelivr.new
  end

  def outdated?(current_version, latest_version)
    Gem::Version.new(current_version) < Gem::Version.new(latest_version)
  rescue ArgumentError
    current_version.to_s < latest_version.to_s
  end

  def get_audit
    uri = self.class.base_uri.dup
    uri.path = '/-/npm/v1/security/advisories/bulk'

    body = packages_with_versions.each.with_object({}) do |(package, version), data|
      data[package] ||= []
      data[package] << version
    end
    return {} if body.empty?

    response = post_json(uri, body)
    JSON.parse(response.body)
  end

  def post_json(uri, body)
    Net::HTTP.post(uri, body.to_json, 'Content-Type' => 'application/json')
  rescue StandardError => e
    raise HTTPError, "Unexpected transport error (#{e.class}: #{e.message})"
  end
end
