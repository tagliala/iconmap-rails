# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

class Iconmap::Packager
  Error        = Class.new(StandardError)
  HTTPError    = Class.new(Error)
  ServiceError = Error.new(Error)

  singleton_class.attr_accessor :endpoint
  self.endpoint = URI('https://api.jspm.io/generate')

  attr_reader :vendor_path

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
    when '200'        then extract_parsed_imports(response)
    when '404', '401' then nil
    else                   handle_failure_response(response)
    end
  end

  def pin_for(package, url)
    %(pin "#{package}", to: "#{url}")
  end

  def vendored_pin_for(package, url)
    filename = package_filename(package)
    version  = extract_package_version_from(url)

    if "#{package}" == filename
      %(pin "#{package}" # #{version})
    else
      %(pin "#{package}", to: "#{filename}" # #{version})
    end
  end

  def packaged?(package)
    iconmap.match(/^pin ["']#{package}["'].*$/)
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

  private

  def post_json(body)
    Net::HTTP.post(self.class.endpoint, body.to_json, 'Content-Type' => 'application/json')
  rescue StandardError => e
    raise HTTPError, "Unexpected transport error (#{e.class}: #{e.message})"
  end

  def normalize_provider(name)
    name.to_s == 'jspm' ? 'jspm.io' : name.to_s
  end

  def extract_parsed_imports(response)
    JSON.parse(response.body).dig('map', 'imports')
  end

  def handle_failure_response(response)
    raise ServiceError, error_message if parse_service_error(response)

    raise HTTPError, "Unexpected response code (#{response.code})"
  end

  def parse_service_error(response)
    JSON.parse(response.body.to_s)['error']
  rescue JSON::ParserError
    nil
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
    with_lines_removed = all_lines.grep_v(/pin ["']#{package}["']/)

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
    package.gsub('/', '--')
  end

  def extract_package_version_from(url)
    url.match(/@\d+\.\d+\.\d+/)&.to_a&.first
  end
end
