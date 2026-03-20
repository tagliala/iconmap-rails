# frozen_string_literal: true

require 'test_helper'

class IconmapTest < ActiveSupport::TestCase
  def setup
    @iconmap = Iconmap::Map.new.tap do |map|
      map.draw do
        pin '@fortawesome/fontawesome-free/svgs/brands/github.svg'
        pin '@fortawesome/fontawesome-free/svgs/brands/instagram.svg'
        pin 'lucide/icons/heart.svg'
      end
    end
  end

  test 'pin records package in packages hash' do
    assert_includes @iconmap.packages, '@fortawesome/fontawesome-free/svgs/brands/github.svg'
    assert_includes @iconmap.packages, 'lucide/icons/heart.svg'
  end

  test 'pin returns a MappedFile' do
    mapped = @iconmap.packages['@fortawesome/fontawesome-free/svgs/brands/github.svg']
    assert_equal '@fortawesome/fontawesome-free/svgs/brands/github.svg', mapped.name
  end

  test 'draw with block' do
    iconmap = Iconmap::Map.new.draw { pin 'test/icon.svg' }
    assert_includes iconmap.packages, 'test/icon.svg'
  end

  test 'draw with file path' do
    file = file_fixture('outdated_icon_map.rb')
    iconmap = Iconmap::Map.new.draw(file)
    assert_includes iconmap.packages, '@fortawesome/fontawesome-free/svgs/brands/github.svg'
  end

  test 'invalid iconmap file results in error' do
    file = file_fixture('invalid_icon_map.rb')
    iconmap = Iconmap::Map.new
    assert_raises Iconmap::Map::InvalidFile do
      iconmap.draw(file)
    end
  end

  test 'draw with nonexistent path does not raise' do
    iconmap = Iconmap::Map.new.draw('/nonexistent/path.rb')
    assert_empty iconmap.packages
  end

  test 'pin clears cache' do
    @iconmap.instance_variable_set(:@cache, { 'test' => 'value' })
    @iconmap.pin 'new/icon.svg'
    assert_empty @iconmap.instance_variable_get(:@cache)
  end

  test 'multiple pins are stored independently' do
    assert_equal 3, @iconmap.packages.size
  end
end
