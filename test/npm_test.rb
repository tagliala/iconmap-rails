# frozen_string_literal: true

require 'test_helper'
require 'iconmap/npm'
require 'minitest/mock'

class Iconmap::NpmTest < ActiveSupport::TestCase
  setup { @npm = Iconmap::Npm.new(file_fixture('outdated_icon_map.rb')) }

  test 'packages_with_versions extracts package name and version from pin lines' do
    packages = @npm.packages_with_versions

    assert_equal 1, packages.size
    assert_equal '@fortawesome/fontawesome-free', packages[0][0]
    assert_equal '6.0.0', packages[0][1]
  end

  test 'packages_with_versions with single quotes' do
    npm = Iconmap::Npm.new(file_fixture('single_quote_outdated_icon_map.rb'))
    packages = npm.packages_with_versions

    assert_equal 1, packages.size
    assert_equal '@fortawesome/fontawesome-free', packages[0][0]
    assert_equal '6.0.0', packages[0][1]
  end

  test 'packages_with_versions without CDN' do
    npm = Iconmap::Npm.new(file_fixture('single_quote_outdated_icon_map_without_cdn.rb'))
    packages = npm.packages_with_versions

    assert_equal 1, packages.size
    assert_equal '@fortawesome/fontawesome-free', packages[0][0]
    assert_equal '6.0.0', packages[0][1]
  end

  test 'successful outdated packages with mock' do
    jsdelivr = Minitest::Mock.new
    jsdelivr.expect :resolve_version, '7.0.0', ['@fortawesome/fontawesome-free']

    @npm.instance_variable_set(:@jsdelivr, jsdelivr)
    outdated_packages = @npm.outdated_packages

    assert_equal 1, outdated_packages.size
    assert_equal '@fortawesome/fontawesome-free', outdated_packages[0].name
    assert_equal '6.0.0', outdated_packages[0].current_version
    assert_equal '7.0.0', outdated_packages[0].latest_version

    jsdelivr.verify
  end

  test 'outdated packages when resolve returns nil' do
    jsdelivr = Minitest::Mock.new
    jsdelivr.expect :resolve_version, nil, ['@fortawesome/fontawesome-free']

    @npm.instance_variable_set(:@jsdelivr, jsdelivr)
    outdated_packages = @npm.outdated_packages

    assert_equal 1, outdated_packages.size
    assert_equal '@fortawesome/fontawesome-free', outdated_packages[0].name
    assert_equal 'Response error', outdated_packages[0].error

    jsdelivr.verify
  end

  test 'outdated packages when package is up to date returns empty' do
    jsdelivr = Minitest::Mock.new
    jsdelivr.expect :resolve_version, '6.0.0', ['@fortawesome/fontawesome-free']

    @npm.instance_variable_set(:@jsdelivr, jsdelivr)
    outdated_packages = @npm.outdated_packages

    assert_empty outdated_packages

    jsdelivr.verify
  end

  test 'successful vulnerable packages with mock' do
    response = Class.new do
      def body
        { '@fortawesome/fontawesome-free' => [{ 'title' => 'XSS in SVG', 'severity' => 'high', 'vulnerable_versions' => '<6.5.0' }] }.to_json
      end

      def code = '200'
    end.new

    @npm.stub(:post_json, response) do
      vulnerable_packages = @npm.vulnerable_packages

      assert_equal 1, vulnerable_packages.size
      assert_equal '@fortawesome/fontawesome-free', vulnerable_packages[0].name
      assert_equal 'XSS in SVG', vulnerable_packages[0].vulnerability
      assert_equal 'high', vulnerable_packages[0].severity
      assert_equal '<6.5.0', vulnerable_packages[0].vulnerable_versions
    end
  end

  test 'failed vulnerable packages request with mock' do
    Net::HTTP.stub(:post, proc { raise 'Unexpected Error' }) do
      assert_raises(Iconmap::Npm::HTTPError) do
        @npm.vulnerable_packages
      end
    end
  end
end
