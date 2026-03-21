# frozen_string_literal: true

require 'test_helper'
require 'iconmap/npm'
require 'minitest/mock'

class Iconmap::NpmIntegrationTest < ActiveSupport::TestCase
  AUDIT_IS_SVG = File.read(File.expand_path('fixtures/files/api/npm_audit_is_svg.json', __dir__))
  AUDIT_FORTAWESOME = File.read(File.expand_path('fixtures/files/api/npm_audit_fortawesome.json', __dir__))

  test 'outdated packages' do
    npm = Iconmap::Npm.new(file_fixture('outdated_icon_map.rb'))

    jsdelivr = Minitest::Mock.new
    jsdelivr.expect :resolve_version, '7.2.0', ['@fortawesome/fontawesome-free']
    npm.instance_variable_set(:@jsdelivr, jsdelivr)

    outdated = npm.outdated_packages

    assert_equal 1, outdated.size
    assert_equal '@fortawesome/fontawesome-free/svgs/brands/github.svg', outdated[0].icon_path
    assert_equal '6.0.0', outdated[0].current_version
    assert_equal '7.2.0', outdated[0].latest_version

    jsdelivr.verify
  end

  test 'outdated packages HTTPError propagates' do
    npm = Iconmap::Npm.new(file_fixture('outdated_icon_map.rb'))

    fake_jsdelivr = Object.new
    def fake_jsdelivr.resolve_version(_pkg)
      raise Iconmap::Jsdelivr::HTTPError, 'transport error'
    end
    npm.instance_variable_set(:@jsdelivr, fake_jsdelivr)

    assert_raises(Iconmap::Jsdelivr::HTTPError) { npm.outdated_packages }
  end

  test 'vulnerable packages' do
    npm = Iconmap::Npm.new(file_fixture('vulnerable_icon_map.rb'))

    response = Struct.new(:code, :body).new('200', AUDIT_IS_SVG)
    npm.stub(:post_json, response) do
      vulnerable = npm.vulnerable_packages

      assert_equal 2, vulnerable.size
      assert_equal 'is-svg', vulnerable[0].name
      assert_equal 'is-svg', vulnerable[1].name

      assert_includes vulnerable.map(&:severity), 'high'
      assert_includes vulnerable.map(&:vulnerability), 'ReDOS in IS-SVG'
      assert_includes vulnerable.map(&:vulnerability), 'Regular Expression Denial of Service (ReDoS)'
      assert_includes vulnerable.map(&:vulnerable_versions), '>=2.1.0 <4.3.0'
      assert_includes vulnerable.map(&:vulnerable_versions), '>=2.1.0 <4.2.2'
    end
  end

  test 'no vulnerabilities returns empty' do
    npm = Iconmap::Npm.new(file_fixture('outdated_icon_map.rb'))

    response = Struct.new(:code, :body).new('200', AUDIT_FORTAWESOME)

    npm.stub(:post_json, response) do
      assert_empty npm.vulnerable_packages
    end
  end

  test 'vulnerable packages HTTPError propagates' do
    npm = Iconmap::Npm.new(file_fixture('vulnerable_icon_map.rb'))

    npm.stub(:post_json, proc { raise Iconmap::Npm::HTTPError, 'transport error' }) do
      assert_raises(Iconmap::Npm::HTTPError) { npm.vulnerable_packages }
    end
  end
end
