# frozen_string_literal: true

require 'test_helper'

class ReloaderTest < ActiveSupport::TestCase
  setup do
    @reloader = Iconmap::Reloader.new
    @config   = Rails.root.join('config/iconmap.rb')
  end

  test 'reload is triggered when iconmap changes' do
    assert_changes -> { @reloader.updated? }, from: false, to: true do
      touch_config
    end
  end

  test 'redraws iconmap when config changes' do
    Rails.application.iconmap = Iconmap::Map.new.draw { pin 'md5', to: 'https://cdn.skypack.dev/md5' }

    assert_not_predicate @reloader, :updated?

    assert_changes -> { Rails.application.iconmap.packages.keys }, from: %w[md5], to: %w[md5 not_there] do
      touch_config

      assert @reloader.execute_if_updated
    end
  end

  private

  def touch_config
    sleep 1
    FileUtils.touch(@config)
  end
end
