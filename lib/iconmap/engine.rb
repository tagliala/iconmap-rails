# frozen_string_literal: true

require_relative 'map'
require_relative 'reloader'

# Use Rails.application.iconmap to access the map
Rails::Application.send(:attr_accessor, :iconmap)

module Iconmap
  class Engine < ::Rails::Engine
    config.iconmap = ActiveSupport::OrderedOptions.new
    config.iconmap.paths = []
    config.iconmap.sweep_cache = Rails.env.local?
    config.iconmap.cache_sweepers = []

    initializer 'iconmap' do |app|
      app.iconmap = Iconmap::Map.new
      app.config.iconmap.paths << app.root.join('config/iconmap.rb')
      app.config.iconmap.paths.each { |path| app.iconmap.draw(path) }
    end

    initializer 'iconmap.reloader' do |app|
      unless app.config.cache_classes
        Iconmap::Reloader.new.tap do |reloader|
          reloader.execute
          app.reloaders << reloader
          app.reloader.to_run { reloader.execute }
        end
      end
    end

    initializer 'iconmap.cache_sweeper' do |app|
      if app.config.iconmap.sweep_cache && !app.config.cache_classes
        app.config.iconmap.cache_sweepers << app.root.join('vendor/icons')
        app.iconmap.cache_sweeper(watches: app.config.iconmap.cache_sweepers)

        ActiveSupport.on_load(:action_controller_base) do
          before_action { Rails.application.iconmap.cache_sweeper.execute_if_updated }
        end
      end
    end

    initializer 'iconmap.assets' do |app|
      if app.config.respond_to?(:assets)
        # When Sprockets and Propshaft are both present the asset paths
        # can contain framework-specific objects. To avoid passing non-string
        # values into Sprockets internals (which call File.expand_path) make
        # sure to push a plain string for Sprockets. Propshaft accepts
        # Pathname values, so prefer that when only Propshaft is available.
        path = Rails.root.join('vendor/icons')

        app.config.assets.paths << if defined?(Sprockets)
                                     path.to_s
                                   else
                                     path
                                   end
      end
    end
  end
end
