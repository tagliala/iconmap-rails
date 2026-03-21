# frozen_string_literal: true

require 'test_helper'
require 'iconmap/commands'
require 'minitest/mock'

class CommandsTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::Isolation

  GITHUB_SVG     = File.read(File.expand_path('fixtures/files/api/fortawesome_github.svg', __dir__))
  GITHUB_CDN_URL = 'https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@7.2.0/svgs/brands/github.svg'

  setup do
    @tmpdir = Dir.mktmpdir
    FileUtils.cp_r("#{__dir__}/dummy", @tmpdir)
    Dir.chdir("#{@tmpdir}/dummy")
    FileUtils.mkdir_p('bin')
    FileUtils.cp("#{__dir__}/../lib/install/bin/iconmap", 'bin/iconmap')
    File.chmod(0o755, 'bin/iconmap')
  end

  teardown do
    FileUtils.remove_entry(@tmpdir) if @tmpdir
  end

  test 'update command prints message of no outdated packages' do
    out, _err = run_iconmap_command('update')

    assert_includes out, 'No outdated'
  end

  test 'outdated command shows full icon paths in table' do
    File.write('config/iconmap.rb', "pin '@fortawesome/fontawesome-free/svgs/brands/github.svg' # @6.0.0\n")

    mock = Minitest::Mock.new
    mock.expect :resolve_version, '7.2.0', ['@fortawesome/fontawesome-free']
    Iconmap::Jsdelivr.stub(:new, mock) do
      out, _err = run_iconmap_command('outdated')

      assert_includes out, '@fortawesome/fontawesome-free/svgs/brands/github.svg'
      assert_includes out, '|'
      assert_includes out, 'outdated'
    end
  end

  test 'pin command pins an icon' do
    mock_jsdelivr = build_github_jsdelivr_mock

    Iconmap::Jsdelivr.stub(:new, mock_jsdelivr) do
      out, _err = run_iconmap_command('pin', '@fortawesome/fontawesome-free/svgs/brands/github.svg')

      assert_includes out, 'Pinning'
    end

    assert_includes File.read('config/iconmap.rb'), "pin '@fortawesome/fontawesome-free/svgs/brands/github.svg'"

    vendored_file = Dir.glob('vendor/icons/@fortawesome--fontawesome-free--svgs--brands--github.svg').first

    assert vendored_file, 'Vendored SVG file should exist'
  end

  test 'packages command lists pinned packages' do
    Iconmap::Jsdelivr.stub(:new, build_github_jsdelivr_mock) do
      run_iconmap_command('pin', '@fortawesome/fontawesome-free/svgs/brands/github.svg')
    end

    out, _err = run_iconmap_command('packages')

    assert_includes out, '@fortawesome/fontawesome-free'
  end

  private

  def run_iconmap_command(command, *args)
    capture_subprocess_io { system('bin/iconmap', command, *args) }
  end

  def build_github_jsdelivr_mock
    mock = Minitest::Mock.new
    mock.expect :resolve_version, '7.2.0', ['@fortawesome/fontawesome-free']
    mock.expect :download_url, GITHUB_CDN_URL,
                ['@fortawesome/fontawesome-free', '7.2.0', 'svgs/brands/github.svg']
    mock.expect :fetch_file, GITHUB_SVG, [GITHUB_CDN_URL]
    mock
  end
end
