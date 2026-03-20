# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

class Iconmap::Jsdelivr
  Error     = Class.new(StandardError)
  HTTPError = Class.new(Error)

  singleton_class.attr_accessor :data_uri, :cdn_uri
  self.data_uri = URI('https://data.jsdelivr.com')
  self.cdn_uri  = URI('https://cdn.jsdelivr.net')

  def resolve_version(package)
    uri = self.class.data_uri.dup
    uri.path = "/v1/packages/npm/#{package}/resolved"

    response = get_json(uri)
    JSON.parse(response)['version']
  rescue JSON::ParserError
    nil
  end

  def download_url(package, version, path)
    "#{self.class.cdn_uri}/npm/#{package}@#{version}/#{path}"
  end

  def fetch_file(url)
    uri = URI(url)
    response = Net::HTTP.get_response(uri)

    case response.code
    when '200' then response.body.dup.force_encoding('UTF-8')
    else raise HTTPError, "Failed to download #{url} (#{response.code})"
    end
  rescue StandardError => e
    raise e if e.is_a?(HTTPError)

    raise HTTPError, "Unexpected transport error (#{e.class}: #{e.message})"
  end

  private

  def get_json(uri)
    request = Net::HTTP::Get.new(uri)
    request['Content-Type'] = 'application/json'
    request['User-Agent'] = 'iconmap-rails'

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    response.body
  rescue StandardError => e
    raise HTTPError, "Unexpected transport error (#{e.class}: #{e.message})"
  end
end
