# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

class Iconmap::Packager
  PIN_REGEX = /#{Iconmap::Map::PIN_REGEX}(.*)/ # :nodoc:
  PRELOAD_OPTION_REGEXP = /preload:\s*(\[[^\]]+\]|true|false|["'][^"']*["'])/ # :nodoc:

  Error        = Class.new(StandardError)
  HTTPError    = Class.new(Error)
  ServiceError = Error.new(Error)

  singleton_class.attr_accessor :endpoint
  self.endpoint = URI('https://api.jspm.io/generate')

  attr_reader :vendor_path

  UNABLE_TO_ANALYZE_REGEXP = %r{Unable to analyze (https://[^\s:]+)}

  def initialize(iconmap_path = 'config/iconmap.rb', vendor_path: 'vendor/icons')
    @iconmap_path = Pathname.new(iconmap_path)
    @vendor_path    = Pathname.new(vendor_path)
  end

  def import(*packages, env: 'production', from: 'jspm')
    response = post_json({
                           'install' => Array(packages),
                           'flattenScope' => true,
                           'env' => ['browser', 'module', env],
                           'provider' => normalize_provider(from)
                         })

    case response.code
    when '200'
      extract_parsed_response(response)
    when '404', '401'
      recover_parse_error(packages, response) # Workaround for jspm/jspm#2636
    else
      handle_failure_response(response)
    end
  end

  def pin_for(package, url = nil, preloads: nil)
    to = url ? %(, to: "#{url}") : ''
    preload_param = preload(preloads)

    %(pin "#{package}") + to + preload_param
  end

  def vendored_pin_for(package, url, preloads = nil)
    filename = package_filename(package)
    version  = extract_package_version_from(url)
    to = package == filename ? nil : filename

    pin_for(package, to, preloads: preloads) + %( # #{version})
  end

  def packaged?(package)
    iconmap.match(Iconmap::Map.pin_line_regexp_for(package))
  end

  def download(package, url)
    ensure_vendor_directory_exists
    remove_existing_package_file(package)
    download_package_file(package, url)
  end

  def remove(package)
    remove_existing_package_file(package)
    remove_package_from_iconmap(package)
  end

  def extract_existing_pin_options(packages)
    return {} unless @iconmap_path.exist?

    packages = Array(packages)

    all_package_options = build_package_options_lookup(iconmap.lines)

    packages.index_with do |package|
      all_package_options[package] || {}
    end
  end

  private

  def build_package_options_lookup(lines)
    lines.each_with_object({}) do |line, package_options|
      match = line.strip.match(PIN_REGEX)

      next unless match

      package_name = match[1]
      options_part = match[2]

      preload_match = options_part.match(PRELOAD_OPTION_REGEXP)

      if preload_match
        preload = preload_from_string(preload_match[1])
        package_options[package_name] = { preload: preload }
      end
    end
  end

  def preload_from_string(value)
    case value
    when 'true'
      true
    when 'false'
      false
    when /^\[.*\]$/
      JSON.parse(value)
    else
      value.gsub(/["']/, '')
    end
  end

  def preload(preloads)
    case Array(preloads)
    in []
      ''
    in ['true'] | [true]
      %(, preload: true)
    in ['false'] | [false]
      %(, preload: false)
    in [string]
      %(, preload: "#{string}")
    else
      %(, preload: #{preloads})
    end
  end

  def post_json(body)
    Net::HTTP.post(self.class.endpoint, body.to_json, 'Content-Type' => 'application/json')
  rescue StandardError => e
    raise HTTPError, "Unexpected transport error (#{e.class}: #{e.message})"
  end

  def normalize_provider(name)
    name.to_s == 'jspm' ? 'jspm.io' : name.to_s
  end

  def extract_parsed_response(response)
    parsed = JSON.parse(response.body)
    imports = parsed.dig('map', 'imports')

    {
      imports: imports
    }
  end

  def handle_failure_response(response)
    if (error_message = parse_service_error(response))
      raise ServiceError, error_message
    else
      raise HTTPError, "Unexpected response code (#{response.code})"
    end
  end

  def parse_service_error(response)
    JSON.parse(response.body.to_s)['error']
  rescue JSON::ParserError
    nil
  end

  def recover_parse_error(packages, response)
    server_error = parse_service_error(response)
    return unless server_error.match?(UNABLE_TO_ANALYZE_REGEXP)

    raise ArgumentError, 'Due to an issue with jspm, it is not possible to add multiple icons from those package.' if packages.many?

    {
      imports: {
        remove_package_version_from(packages[0]) => server_error.match(UNABLE_TO_ANALYZE_REGEXP)[1]
      }
    }
  end

  def iconmap
    @iconmap ||= File.read(@iconmap_path)
  end

  def ensure_vendor_directory_exists
    FileUtils.mkdir_p @vendor_path
  end

  def remove_existing_package_file(package)
    FileUtils.rm_rf vendored_package_path(package)
  end

  def remove_package_from_iconmap(package)
    all_lines = File.readlines(@iconmap_path)
    with_lines_removed = all_lines.grep_v(Iconmap::Map.pin_line_regexp_for(package))

    File.open(@iconmap_path, 'w') do |file|
      with_lines_removed.each { |line| file.write(line) }
    end
  end

  def download_package_file(package, url)
    response = Net::HTTP.get_response(URI(url))

    if response.code == '200'
      save_vendored_package(package, url, response.body)
    else
      handle_failure_response(response)
    end
  end

  def save_vendored_package(package, url, source)
    File.open(vendored_package_path(package), 'w+') do |vendored_package|
      vendored_package.write "<!-- #{package}#{extract_package_version_from(url)} downloaded from #{url} -->\n\n"

      vendored_package.write remove_sourcemap_comment_from(source).force_encoding('UTF-8')
    end
  end

  def remove_sourcemap_comment_from(source)
    source.gsub(%r{^//# sourceMappingURL=.*}, '')
  end

  def vendored_package_path(package)
    @vendor_path.join(package_filename(package))
  end

  def package_filename(package)
    "#{package.gsub('/', '--')}"
  end

  def extract_package_version_from(url)
    url.match(/@\d+\.\d+\.\d+/)&.to_a&.first
  end

  def remove_package_version_from(url)
    url.gsub(/@\d+\.\d+\.\d+/, '')
  end
end
