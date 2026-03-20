# frozen_string_literal: true

require 'test_helper'
require 'iconmap/packager'
require 'minitest/mock'

class Iconmap::PackagerIntegrationTest < ActiveSupport::TestCase
  GITHUB_SVG     = File.read(File.expand_path('fixtures/files/api/fortawesome_github.svg', __dir__))
  GITHUB_CDN_URL = 'https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@7.2.0/svgs/brands/github.svg'

  setup do
    @config = Tempfile.new(['iconmap', '.rb'])
    @config.write("# frozen_string_literal: true\n\n")
    @config.rewind
  end

  teardown { @config.close! }

  test 'pin resolves version and downloads SVG' do
    Dir.mktmpdir do |vendor_dir|
      packager = Iconmap::Packager.new(@config.path, vendor_path: vendor_dir)

      jsdelivr = Minitest::Mock.new
      jsdelivr.expect :resolve_version, '7.2.0', ['@fortawesome/fontawesome-free']
      jsdelivr.expect :download_url, GITHUB_CDN_URL,
                      ['@fortawesome/fontawesome-free', '7.2.0', 'svgs/brands/github.svg']
      jsdelivr.expect :fetch_file, GITHUB_SVG, [GITHUB_CDN_URL]
      packager.instance_variable_set(:@jsdelivr, jsdelivr)

      pin_line = packager.pin('@fortawesome/fontawesome-free/svgs/brands/github.svg')

      assert_equal %(pin '@fortawesome/fontawesome-free/svgs/brands/github.svg' # @7.2.0), pin_line

      vendored_file = Pathname.new(vendor_dir).join('@fortawesome--fontawesome-free--svgs--brands--github.svg')
      assert_path_exists vendored_file

      content = File.read(vendored_file)
      assert_match %r{<!-- @fortawesome/fontawesome-free/svgs/brands/github\.svg@7\.2\.0 downloaded from .* -->}, content
      assert_includes content, '<svg'

      jsdelivr.verify
    end
  end

  test 'pin with explicit version skips resolve' do
    cdn_url = 'https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6.5.0/svgs/brands/github.svg'

    Dir.mktmpdir do |vendor_dir|
      packager = Iconmap::Packager.new(@config.path, vendor_path: vendor_dir)

      jsdelivr = Minitest::Mock.new
      jsdelivr.expect :download_url, cdn_url,
                      ['@fortawesome/fontawesome-free', '6.5.0', 'svgs/brands/github.svg']
      jsdelivr.expect :fetch_file, GITHUB_SVG, [cdn_url]
      packager.instance_variable_set(:@jsdelivr, jsdelivr)

      pin_line = packager.pin('@fortawesome/fontawesome-free@6.5.0/svgs/brands/github.svg')

      assert_equal %(pin '@fortawesome/fontawesome-free/svgs/brands/github.svg' # @6.5.0), pin_line

      vendored_file = Pathname.new(vendor_dir).join('@fortawesome--fontawesome-free--svgs--brands--github.svg')
      assert_path_exists vendored_file

      jsdelivr.verify
    end
  end

  test 'remove deletes vendored file and pin' do
    Dir.mktmpdir do |vendor_dir|
      config = Tempfile.new(['iconmap', '.rb'])
      config.write("pin '@fortawesome/fontawesome-free/svgs/brands/github.svg' # @7.2.0\n")
      config.rewind

      packager = Iconmap::Packager.new(config.path, vendor_path: vendor_dir)

      vendored_file = Pathname.new(vendor_dir).join('@fortawesome--fontawesome-free--svgs--brands--github.svg')
      File.write(vendored_file, GITHUB_SVG)

      packager.remove('@fortawesome/fontawesome-free/svgs/brands/github.svg')

      assert_not File.exist?(vendored_file)
      assert_not packager.packaged?('@fortawesome/fontawesome-free/svgs/brands/github.svg')
    ensure
      config.close!
    end
  end
end
