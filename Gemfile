# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in iconmap-rails.gemspec.
gemspec

gem 'rails', '~> 8.0.0'
gem 'sprockets-rails'

gem 'sqlite3', '~> 2.5'

group :development do
  gem 'appraisal'

  gem 'rubocop', require: false
  gem 'rubocop-capybara', require: false
  gem 'rubocop-minitest', require: false
  gem 'rubocop-packaging', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rake', require: false
end

group :test do
  gem 'stimulus-rails'
  gem 'turbo-rails'

  gem 'byebug'

  gem 'capybara'
  gem 'rexml'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end
