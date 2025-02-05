# frozen_string_literal: true

require 'test_helper'

class Iconmap::IconmapTagsHelperTest < ActionView::TestCase
  attr_reader :request

  class FakeRequest
    def initialize(nonce = nil)
      @nonce = nonce
    end

    def send_early_hints(links); end

    def content_security_policy
      Object.new if @nonce
    end

    def content_security_policy_nonce
      @nonce
    end
  end

  test 'javascript_inline_iconmap_tag' do
    assert_match \
      %r{<script type="iconmap" data-turbo-track="reload">{\n  \"imports\": {\n    \"md5\": \"https://cdn.skypack.dev/md5\",\n    \"not_there\": \"/nowhere.js\"\n  }\n}</script>},
      javascript_inline_iconmap_tag
  end

  test 'javascript_iconmap_module_preload_tags' do
    assert_dom_equal \
      %(<link rel="modulepreload" href="https://cdn.skypack.dev/md5">),
      javascript_iconmap_module_preload_tags
  end

  test 'tags have no nonce if CSP is not configured' do
    @request = FakeRequest.new

    assert_no_match(/nonce/, javascript_iconmap_tags('application'))
  ensure
    @request = nil
  end

  test 'tags have nonce if CSP is configured' do
    @request = FakeRequest.new('iyhD0Yc0W+c=')

    assert_match(/nonce="iyhD0Yc0W\+c="/, javascript_inline_iconmap_tag)
    assert_match(/nonce="iyhD0Yc0W\+c="/, javascript_import_module_tag('application'))
    assert_match(/nonce="iyhD0Yc0W\+c="/, javascript_iconmap_module_preload_tags)
  ensure
    @request = nil
  end

  test 'using a custom iconmap' do
    iconmap = Iconmap::Map.new
    iconmap.pin 'foo', preload: true
    iconmap.pin 'bar', preload: false
    iconmap_html = javascript_iconmap_tags('foo', iconmap: iconmap)

    assert_includes iconmap_html, %(<script type="iconmap" data-turbo-track="reload">)
    assert_includes iconmap_html, %("foo": "/foo.js")
    assert_includes iconmap_html, %("bar": "/bar.js")
    assert_includes iconmap_html, %(<link rel="modulepreload" href="/foo.js">)
    assert_not_includes iconmap_html, %(<link rel="modulepreload" href="/bar.js">)
    assert_includes iconmap_html, %(<script type="module">import "foo"</script>)
  end
end
