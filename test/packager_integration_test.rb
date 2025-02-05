# frozen_string_literal: true

require 'test_helper'
require 'iconmap/packager'

class Iconmap::PackagerIntegrationTest < ActiveSupport::TestCase
  setup { @packager = Iconmap::Packager.new(Rails.root.join('config/iconmap.rb')) }

  test 'successful import against live service' do
    assert_equal 'https://ga.jspm.io/npm:react@17.0.2/index.js', @packager.import('react@17.0.2')['react']
  end

  test 'missing import against live service' do
    assert_nil @packager.import('react-is-not-this-package@17.0.2')
  end

  test 'failed request against live bad domain' do
    original_endpoint = Iconmap::Packager.endpoint
    Iconmap::Packager.endpoint = URI('https://invalid./error')

    assert_raises(Iconmap::Packager::HTTPError) do
      @packager.import('missing-package-that-doesnt-exist@17.0.2')
    end
  ensure
    Iconmap::Packager.endpoint = original_endpoint
  end

  test 'successful downloads from live service' do
    Dir.mktmpdir do |vendor_dir|
      @packager = Iconmap::Packager.new \
        Rails.root.join('config/iconmap.rb'),
        vendor_path: Pathname.new(vendor_dir)

      package_url = 'https://ga.jspm.io/npm:@github/webauthn-json@0.5.7/dist/main/webauthn-json.js'
      @packager.download('@github/webauthn-json', package_url)
      vendored_package_file = Pathname.new(vendor_dir).join('@github--webauthn-json.js')

      assert_path_exists vendored_package_file
      assert_equal "// @github/webauthn-json@0.5.7 downloaded from #{package_url}", File.readlines(vendored_package_file).first.strip

      package_url = 'https://ga.jspm.io/npm:react@17.0.2/index.js'
      vendored_package_file = Pathname.new(vendor_dir).join('react.js')
      @packager.download('react', package_url)

      assert_path_exists vendored_package_file
      assert_equal "// react@17.0.2 downloaded from #{package_url}", File.readlines(vendored_package_file).first.strip

      @packager.remove('react')

      assert_not File.exist?(Pathname.new(vendor_dir).join('react.js'))
    end
  end
end
