# frozen_string_literal: true

require 'test_helper'
require 'json'

class CommandsTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::Isolation

  setup do
    @tmpdir = Dir.mktmpdir
    FileUtils.cp_r("#{__dir__}/dummy", @tmpdir)
    Dir.chdir("#{@tmpdir}/dummy")
    FileUtils.cp("#{__dir__}/../lib/install/bin/iconmap", 'bin')
  end

  teardown do
    FileUtils.remove_entry(@tmpdir) if @tmpdir
  end

  test 'update command prints message of no outdated packages' do
    out, _err = run_iconmap_command('update')

    assert_includes out, 'No outdated'
  end

  test 'pin command pins an icon from jsdelivr' do
    out, _err = run_iconmap_command('pin', '@fortawesome/fontawesome-free/svgs/brands/github.svg')

    assert_includes out, 'Pinning'
    assert_includes File.read("#{@tmpdir}/dummy/config/iconmap.rb"), "pin '@fortawesome/fontawesome-free/svgs/brands/github.svg'"

    vendored_file = Dir.glob("#{@tmpdir}/dummy/vendor/icons/@fortawesome--fontawesome-free--svgs--brands--github.svg").first
    assert vendored_file, 'Vendored SVG file should exist'
  end

  test 'packages command lists pinned packages' do
    # First pin something
    run_iconmap_command('pin', '@fortawesome/fontawesome-free/svgs/brands/github.svg')

    out, _err = run_iconmap_command('packages')

    assert_includes out, '@fortawesome/fontawesome-free'
  end

  private

  def run_iconmap_command(command, *args)
    capture_subprocess_io { system('bin/iconmap', command, *args, exception: true) }
  end
end
