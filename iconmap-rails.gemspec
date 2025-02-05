# frozen_string_literal: true

require_relative 'lib/iconmap/version'

Gem::Specification.new do |spec|
  spec.name        = 'iconmap-rails'
  spec.version     = Iconmap::VERSION
  spec.authors     = ['Geremia Taglialatela']
  spec.email       = 'tagliala.dev@gmail.com'
  spec.homepage    = 'https://github.com/tagliala/iconmap-rails'
  spec.summary     = 'Use ESM with importmap to manage modern JavaScript in Rails without transpiling or bundling.'
  spec.license     = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/tagliala/iconmap-rails'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['{app,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  spec.required_ruby_version = '>= 3.1.0'

  spec.add_dependency 'actionpack', '>= 7.1.0'
  spec.add_dependency 'activesupport', '>= 7.1.0'
  spec.add_dependency 'railties', '>= 7.1.0'
end
