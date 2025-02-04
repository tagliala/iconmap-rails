require "test_helper"
require "rails/generators/rails/app/app_generator"

class InstallerTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::Isolation

  test "installer task" do
    with_new_rails_app do
      run_command("bin/rails", "iconmap:install")

      assert_equal 0, File.size("vendor/icons/.keep")
      assert_equal File.read("#{__dir__}/../lib/install/config/iconmap.rb"), File.read("config/iconmap.rb")
      assert_equal File.read("#{__dir__}/../lib/install/bin/iconmap"), File.read("bin/iconmap")
      assert_equal 0700, File.stat("bin/iconmap").mode & 0700

      if defined?(Sprockets)
        manifest = File.read("app/assets/config/manifest.js")
        assert_match "//= link_tree ../../../vendor/icons .svg", manifest
      end
    end
  end

  test "doesn't load rakefile twice" do
    with_new_rails_app do |app_dir|
      rakefile = File.read("#{app_dir}/Rakefile")
      rakefile = "puts \"I've been logged twice!\" \n" + rakefile
      File.write("#{app_dir}/Rakefile", rakefile)

      out, err = run_command("bin/rails", "iconmap:install")

      assert_equal 1, out.scan(/I've been logged twice!/).size
    end
  end

  private
    def with_new_rails_app
      Dir.mktmpdir do |tmpdir|
        app_dir = "#{tmpdir}/my_cool_app"

        Rails::Generators::AppGenerator.start([app_dir, "--quiet", "--skip-bundle", "--skip-bootsnap"])

        Dir.chdir(app_dir) do
          gemfile = File.read("Gemfile")
          gemfile.gsub!(/^gem "iconmap-rails".*/, "")
          gemfile << %(gem "iconmap-rails", path: #{File.expand_path("..", __dir__).inspect}\n)
          if Rails::VERSION::PRE == "alpha"
            gemfile.gsub!(/^gem "rails".*/, "")
            gemfile << %(gem "rails", path: #{Gem.loaded_specs["rails"].full_gem_path.inspect}\n)
          end
          File.write("Gemfile", gemfile)

          run_command("bundle", "install")

          yield(app_dir)
        end
      end
    end

    def run_command(*command)
      Bundler.with_unbundled_env do
        capture_subprocess_io { system(*command, exception: true) }
      end
    end
end
