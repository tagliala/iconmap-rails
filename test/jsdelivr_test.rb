# frozen_string_literal: true

require 'test_helper'
require 'iconmap/jsdelivr'
require 'minitest/mock'

class Iconmap::JsdelivrTest < ActiveSupport::TestCase
  setup { @jsdelivr = Iconmap::Jsdelivr.new }

  test 'resolve_version returns version string' do
    json_response = { 'version' => '7.0.0' }.to_json

    @jsdelivr.stub(:get_json, json_response) do
      assert_equal '7.0.0', @jsdelivr.resolve_version('@fortawesome/fontawesome-free')
    end
  end

  test 'resolve_version returns nil on parse error' do
    @jsdelivr.stub(:get_json, 'invalid json{{{') do
      assert_nil @jsdelivr.resolve_version('@fortawesome/fontawesome-free')
    end
  end

  test 'download_url builds correct CDN URL' do
    url = @jsdelivr.download_url('@fortawesome/fontawesome-free', '7.0.0', 'svgs/brands/github.svg')
    assert_equal 'https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@7.0.0/svgs/brands/github.svg', url
  end

  test 'download_url for unscoped package' do
    url = @jsdelivr.download_url('lucide', '1.0.0', 'icons/heart.svg')
    assert_equal 'https://cdn.jsdelivr.net/npm/lucide@1.0.0/icons/heart.svg', url
  end

  test 'fetch_file raises HTTPError on non-200' do
    response = Struct.new(:code, :body).new('404', 'Not Found')

    Net::HTTP.stub(:get_response, response) do
      assert_raises(Iconmap::Jsdelivr::HTTPError) do
        @jsdelivr.fetch_file('https://cdn.jsdelivr.net/npm/test@1.0.0/missing.svg')
      end
    end
  end

  test 'fetch_file raises HTTPError on transport error' do
    Net::HTTP.stub(:get_response, proc { raise SocketError, 'Failed to connect' }) do
      assert_raises(Iconmap::Jsdelivr::HTTPError) do
        @jsdelivr.fetch_file('https://cdn.jsdelivr.net/npm/test@1.0.0/icon.svg')
      end
    end
  end

  test 'fetch_file returns body on success' do
    response = Struct.new(:code, :body).new('200', '<svg>test</svg>')

    Net::HTTP.stub(:get_response, response) do
      assert_equal '<svg>test</svg>', @jsdelivr.fetch_file('https://cdn.jsdelivr.net/npm/test@1.0.0/icon.svg')
    end
  end
end
