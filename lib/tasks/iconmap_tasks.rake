# frozen_string_literal: true

namespace :iconmap do
  desc 'Setup Iconmap for the app'
  task :install do
    previous_location = ENV.fetch('LOCATION', nil)
    ENV['LOCATION'] = File.expand_path('../install/install.rb', __dir__)
    Rake::Task['app:template'].invoke
    ENV['LOCATION'] = previous_location
  end
end
