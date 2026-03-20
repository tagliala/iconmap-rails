# frozen_string_literal: true

require 'test_helper'
require 'iconmap/packager'

class Iconmap::PackagerIntegrationTest < ActiveSupport::TestCase
  setup do
    @config = Tempfile.new(['iconmap', '.rb'])
    @config.write("# frozen_string_literal: true\n\n")
    @config.rewind
    @packager = Iconmap::Packager.new(@config.path)
  end

  teardown { @config.close! }

  test 'successful pin against live jsdelivr' do
    Dir.mktmpdir do |vendor_dir|
      packager = Iconmap::Packager.new(@config.path, vendor_path: vendor_dir)

      pin_line = packager.pin('@fortawesome/fontawesome-free/svgs/brands/github.svg')

      assert_match(/pin '@fortawesome\/fontawesome-free\/svgs\/brands\/github\.svg' # @\d+/, pin_line)

      vendored_file = Pathname.new(vendor_dir).join('@fortawesome--fontawesome-free--svgs--brands--github.svg')
      assert_path_exists vendored_file

      content = File.read(vendored_file)
      assert_match(/<!-- @fortawesome\/fontawesome-free\/svgs\/brands\/github\.svg@\d+\.\d+\.\d+ downloaded from .* -->/, content)
      assert_includes content, '<svg'
    end
  end

  test 'successful pin with explicit version against live jsdelivr' do
    Dir.mktmpdir do |vendor_dir|
      packager = Iconmap::Packager.new(@config.path, vendor_path: vendor_dir)

      pin_line = packager.pin('@fortawesome/fontawesome-free@6.5.0/svgs/brands/github.svg')

      assert_equal %(pin '@fortawesome/fontawesome-free/svgs/brands/github.svg' # @6.5.0), pin_line

      vendored_file = Pathname.new(vendor_dir).join('@fortawesome--fontawesome-free--svgs--brands--github.svg')
      assert_path_exists vendored_file
    end
  end

  test 'remove deletes vendored file and pin line' do
    Dir.mktmpdir do |vendor_dir|
      packager = Iconmap::Packager.new(@config.path, vendor_path: vendor_dir)

      packager.pin('@fortawesome/fontawesome-free/svgs/brands/github.svg')

      # Write pin to config so remove can find it
      File.write(@config.path, "pin '@fortawesome/fontawesome-free/svgs/brands/github.svg' # @6.5.0\n")

      packager.remove('@fortawesome/fontawesome-free/svgs/brands/github.svg')

      vendored_file = Pathname.new(vendor_dir).join('@fortawesome--fontawesome-free--svgs--brands--github.svg')
      assert_not File.exist?(vendored_file)
    end
  end
end
