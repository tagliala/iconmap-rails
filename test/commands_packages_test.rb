# frozen_string_literal: true

require 'test_helper'
require 'iconmap/commands'

class CommandsPackagesTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::Isolation

  test 'packages command does not duplicate entries' do
    tmpdir = Dir.mktmpdir
    FileUtils.cp_r("#{__dir__}/dummy", tmpdir)
    Dir.chdir("#{tmpdir}/dummy") do
      FileUtils.mkdir_p('bin')
      FileUtils.cp("#{__dir__}/../lib/install/bin/iconmap", 'bin/iconmap')
      File.chmod(0o755, 'bin/iconmap')

      # prepare config with two distinct pins
      File.write('config/iconmap.rb', <<~RUBY)
        pin '@fortawesome/fontawesome-free/svgs/brands/instagram.svg' # @7.2.0
        pin '@fortawesome/fontawesome-free/svgs/brands/github.svg'    # @7.2.0
      RUBY

      out, _err = capture_subprocess_io { system('bin/iconmap', 'packages') }

      lines = out.split("\n").reject(&:empty?)
      # ensure each package appears only once
      packages = lines.map { |l| l.split(' ').first }

      assert_equal packages.uniq, packages
    end
  end
end
