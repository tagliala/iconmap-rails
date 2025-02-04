require "test_helper"
require "iconmap/packager"

class Iconmap::PackagerSingleQuotesTest < ActiveSupport::TestCase
  setup do
    @single_quote_config_name = Rails.root.join("config/iconmap_with_single_quotes.rb")
    File.write(@single_quote_config_name, File.read(Rails.root.join("config/iconmap.rb")).tr('"', "'"))
    @packager = Iconmap::Packager.new(@single_quote_config_name)
  end

  teardown { File.delete(@single_quote_config_name) }

  test "packaged? with single quotes" do
    assert @packager.packaged?("md5")
    assert_not @packager.packaged?("md5-extension")
  end

  test "remove package with single quotes" do
    assert @packager.remove("md5")
    assert_not @packager.packaged?("md5")
  end
end
