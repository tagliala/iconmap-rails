# frozen_string_literal: true

require 'test_helper'
require 'iconmap/packager'
require 'minitest/mock'

class Iconmap::PackagerTest < ActiveSupport::TestCase
  setup do
    @config = Tempfile.new(['iconmap', '.rb'])
    @config.write("# frozen_string_literal: true\n\npin '@fortawesome/fontawesome-free/svgs/brands/github.svg' # @6.0.0\n")
    @config.rewind
    @packager = Iconmap::Packager.new(@config.path)
  end

  teardown { @config.close! }

  test 'parse_icon_path with scoped package and version' do
    result = @packager.parse_icon_path('@fortawesome/fontawesome-free@7.0.0/svgs/brands/github.svg')

    assert_equal '@fortawesome/fontawesome-free', result[:package]
    assert_equal 'svgs/brands/github.svg', result[:path]
    assert_equal '7.0.0', result[:version]
  end

  test 'parse_icon_path with scoped package without version' do
    result = @packager.parse_icon_path('@fortawesome/fontawesome-free/svgs/brands/instagram.svg')

    assert_equal '@fortawesome/fontawesome-free', result[:package]
    assert_equal 'svgs/brands/instagram.svg', result[:path]
    assert_nil result[:version]
  end

  test 'parse_icon_path with unscoped package and version' do
    result = @packager.parse_icon_path('lucide@1.0.0/icons/heart.svg')

    assert_equal 'lucide', result[:package]
    assert_equal 'icons/heart.svg', result[:path]
    assert_equal '1.0.0', result[:version]
  end

  test 'parse_icon_path with unscoped package without version' do
    result = @packager.parse_icon_path('lucide/icons/heart.svg')

    assert_equal 'lucide', result[:package]
    assert_equal 'icons/heart.svg', result[:path]
    assert_nil result[:version]
  end

  test 'vendored_pin_for' do
    assert_equal %(pin '@fortawesome/fontawesome-free/svgs/brands/github.svg' # @7.0.0),
                 @packager.vendored_pin_for('@fortawesome/fontawesome-free', 'svgs/brands/github.svg', '7.0.0')
  end

  test 'vendored_filename' do
    assert_equal '@fortawesome--fontawesome-free--svgs--brands--github.svg',
                 @packager.vendored_filename('@fortawesome/fontawesome-free', 'svgs/brands/github.svg')
  end

  test 'vendored_filename for unscoped package' do
    assert_equal 'lucide--icons--heart.svg',
                 @packager.vendored_filename('lucide', 'icons/heart.svg')
  end

  test 'packaged?' do
    assert @packager.packaged?('@fortawesome/fontawesome-free/svgs/brands/github.svg')
    assert_not @packager.packaged?('@fortawesome/fontawesome-free/svgs/brands/instagram.svg')
  end

  test 'pin resolves version and downloads' do
    jsdelivr = Minitest::Mock.new
    jsdelivr.expect :resolve_version, '7.0.0', ['@fortawesome/fontawesome-free']
    jsdelivr.expect :download_url, 'https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@7.0.0/svgs/brands/instagram.svg',
                    ['@fortawesome/fontawesome-free', '7.0.0', 'svgs/brands/instagram.svg']
    jsdelivr.expect :fetch_file, '<svg>icon</svg>',
                    ['https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@7.0.0/svgs/brands/instagram.svg']

    Dir.mktmpdir do |vendor_dir|
      packager = Iconmap::Packager.new(@config.path, vendor_path: vendor_dir)
      packager.instance_variable_set(:@jsdelivr, jsdelivr)

      result = packager.pin('@fortawesome/fontawesome-free/svgs/brands/instagram.svg')

      assert_equal %(pin '@fortawesome/fontawesome-free/svgs/brands/instagram.svg' # @7.0.0), result
      assert_path_exists Pathname.new(vendor_dir).join('@fortawesome--fontawesome-free--svgs--brands--instagram.svg')

      jsdelivr.verify
    end
  end

  test 'pin with explicit version skips resolve' do
    jsdelivr = Minitest::Mock.new
    jsdelivr.expect :download_url, 'https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@7.0.0/svgs/brands/github.svg',
                    ['@fortawesome/fontawesome-free', '7.0.0', 'svgs/brands/github.svg']
    jsdelivr.expect :fetch_file, '<svg>icon</svg>',
                    ['https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@7.0.0/svgs/brands/github.svg']

    Dir.mktmpdir do |vendor_dir|
      packager = Iconmap::Packager.new(@config.path, vendor_path: vendor_dir)
      packager.instance_variable_set(:@jsdelivr, jsdelivr)

      result = packager.pin('@fortawesome/fontawesome-free@7.0.0/svgs/brands/github.svg')

      assert_equal %(pin '@fortawesome/fontawesome-free/svgs/brands/github.svg' # @7.0.0), result

      jsdelivr.verify
    end
  end

  test 'download saves vendored file with provenance comment' do
    jsdelivr = Minitest::Mock.new
    jsdelivr.expect :download_url, 'https://cdn.jsdelivr.net/npm/lucide@1.0.0/icons/heart.svg',
                    ['lucide', '1.0.0', 'icons/heart.svg']
    jsdelivr.expect :fetch_file, '<svg>heart</svg>',
                    ['https://cdn.jsdelivr.net/npm/lucide@1.0.0/icons/heart.svg']

    Dir.mktmpdir do |vendor_dir|
      packager = Iconmap::Packager.new(@config.path, vendor_path: vendor_dir)
      packager.instance_variable_set(:@jsdelivr, jsdelivr)

      packager.download('lucide', '1.0.0', 'icons/heart.svg')

      vendored_file = Pathname.new(vendor_dir).join('lucide--icons--heart.svg')

      assert_path_exists vendored_file

      content = File.read(vendored_file)

      assert_match %r{<!-- lucide/icons/heart\.svg@1\.0\.0 downloaded from .* -->}, content
      assert_includes content, '<svg>heart</svg>'

      jsdelivr.verify
    end
  end

  test 'remove deletes vendored file and removes pin from iconmap' do
    Dir.mktmpdir do |vendor_dir|
      packager = Iconmap::Packager.new(@config.path, vendor_path: vendor_dir)

      vendored_file = Pathname.new(vendor_dir).join('@fortawesome--fontawesome-free--svgs--brands--github.svg')
      File.write(vendored_file, '<svg>test</svg>')

      packager.remove('@fortawesome/fontawesome-free/svgs/brands/github.svg')

      assert_not File.exist?(vendored_file)
      assert_not packager.packaged?('@fortawesome/fontawesome-free/svgs/brands/github.svg')
    end
  end
end
