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

  test 'json command prints JSON with imports' do
    out, = run_iconmap_command('json')

    assert_includes JSON.parse(out), 'imports'
  end

  test 'update command prints message of no outdated packages' do
    out, _err = run_iconmap_command('update')

    assert_includes out, 'No outdated'
  end

  test 'update command prints confirmation of pin with outdated packages' do
    @tmpdir = Dir.mktmpdir
    FileUtils.cp_r("#{__dir__}/dummy", @tmpdir)
    Dir.chdir("#{@tmpdir}/dummy")
    FileUtils.cp("#{__dir__}/fixtures/files/outdated_icon_map.rb", "#{@tmpdir}/dummy/config/iconmap.rb")
    FileUtils.cp("#{__dir__}/../lib/install/bin/iconmap", 'bin')

    out, _err = run_iconmap_command('update')

    assert_includes out, 'Pinning'
  end

  test 'pristine command redownloads all pinned packages' do
    @tmpdir = Dir.mktmpdir
    FileUtils.cp_r("#{__dir__}/dummy", @tmpdir)
    Dir.chdir("#{@tmpdir}/dummy")
    FileUtils.cp("#{__dir__}/fixtures/files/outdated_icon_map.rb", "#{@tmpdir}/dummy/config/iconmap.rb")
    FileUtils.cp("#{__dir__}/../lib/install/bin/iconmap", 'bin')
    out, _err = run_iconmap_command('pin', 'md5@2.2.0')

    assert_includes out, 'Pinning "md5" to vendor/javascript/md5.js via download from https://ga.jspm.io/npm:md5@2.2.0/md5.js'

    original = File.read("#{@tmpdir}/dummy/vendor/javascript/md5.js")
    File.write("#{@tmpdir}/dummy/vendor/javascript/md5.js", 'corrupted')

    out, _err = run_iconmap_command('pristine')

    assert_includes out, 'Downloading "md5" to vendor/javascript/md5.js from https://ga.jspm.io/npm:md5@2.2.0'
    assert_equal original, File.read("#{@tmpdir}/dummy/vendor/javascript/md5.js")
  end

  private

  def run_iconmap_command(command, *args)
    capture_subprocess_io { system('bin/iconmap', command, *args, exception: true) }
  end
end
