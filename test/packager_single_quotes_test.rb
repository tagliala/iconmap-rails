# frozen_string_literal: true

require 'test_helper'
require 'iconmap/packager'

class Iconmap::PackagerSingleQuotesTest < ActiveSupport::TestCase
  setup do
    @config = Tempfile.new(['iconmap', '.rb'])
    @config.write("# frozen_string_literal: true\n\npin '@fortawesome/fontawesome-free/svgs/brands/github.svg' # @6.0.0\n")
    @config.rewind
    @packager = Iconmap::Packager.new(@config.path)
  end

  teardown { @config.close! }

  test 'packaged? with single quotes' do
    assert @packager.packaged?('@fortawesome/fontawesome-free/svgs/brands/github.svg')
    assert_not @packager.packaged?('@fortawesome/fontawesome-free/svgs/brands/instagram.svg')
  end

  test 'remove package with single quotes' do
    Dir.mktmpdir do |vendor_dir|
      packager = Iconmap::Packager.new(@config.path, vendor_path: vendor_dir)
      packager.remove('@fortawesome/fontawesome-free/svgs/brands/github.svg')
      assert_not packager.packaged?('@fortawesome/fontawesome-free/svgs/brands/github.svg')
    end
  end
end
