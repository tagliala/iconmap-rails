# frozen_string_literal: true

require 'test_helper'
require 'iconmap/reloader'

class IconmapReloaderTest < ActiveSupport::TestCase
  test 'reloader redraws iconmap when pin file changes' do
    # Ensure we start with a clean map
    Rails.application.iconmap.draw(Rails.root.join('test/dummy/config/iconmap.rb'))

    # Write a temporary pin file to simulate a change
    temp_path = Rails.root.join('tmp/test_iconmap.rb')
    File.write(temp_path, "pin 'some-package/icons/x.svg'\n")

    begin
      # Add the temp path to config paths and construct a reloader
      # config.iconmap.paths may be frozen (set by engine); duplicate and replace for test
      paths = Rails.application.config.iconmap.paths.dup
      paths << temp_path
      Rails.application.config.iconmap.paths = paths
      reloader = Iconmap::Reloader.new

      # Execute the reloader which should draw the new file
      reloader.execute

      assert_includes Rails.application.iconmap.packages.keys, 'some-package/icons/x.svg'
    ensure
      # Cleanup
      # restore original paths
      Rails.application.config.iconmap.paths = Rails.application.config.iconmap.paths.reject { |p| p.to_s == temp_path.to_s }
      File.delete(temp_path) if File.exist?(temp_path)
    end
  end
end
