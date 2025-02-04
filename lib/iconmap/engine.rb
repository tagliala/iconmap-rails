require_relative "map"

# Use Rails.application.iconmap to access the map
Rails::Application.send(:attr_accessor, :iconmap)

module Iconmap
  class Engine < ::Rails::Engine
    config.iconmap = ActiveSupport::OrderedOptions.new
    config.iconmap.paths = []
    config.iconmap.sweep_cache = Rails.env.development? || Rails.env.test?
    config.iconmap.cache_sweepers = []
    config.iconmap.rescuable_asset_errors = []

    config.autoload_once_paths = %W( #{root}/app/helpers #{root}/app/controllers )

    initializer "iconmap" do |app|
      app.iconmap = Iconmap::Map.new
      app.config.iconmap.paths << app.root.join("config/iconmap.rb")
      app.config.iconmap.paths.each { |path| app.iconmap.draw(path) }
    end

    initializer "iconmap.reloader" do |app|
      unless app.config.cache_classes
        Iconmap::Reloader.new.tap do |reloader|
          reloader.execute
          app.reloaders << reloader
          app.reloader.to_run { reloader.execute }
        end
      end
    end

    initializer "iconmap.cache_sweeper" do |app|
      if app.config.iconmap.sweep_cache && !app.config.cache_classes
        app.config.iconmap.cache_sweepers << app.root.join("vendor/icons")
        app.iconmap.cache_sweeper(watches: app.config.iconmap.cache_sweepers)

        ActiveSupport.on_load(:action_controller_base) do
          before_action { Rails.application.iconmap.cache_sweeper.execute_if_updated }
        end
      end
    end

    initializer "iconmap.assets" do |app|
      if app.config.respond_to?(:assets)
        app.config.assets.paths << Rails.root.join("vendor/icons")
      end
    end

    initializer "iconmap.concerns" do
      ActiveSupport.on_load(:action_controller_base) do
        extend Iconmap::Freshness
      end
    end

    initializer "iconmap.helpers" do
      ActiveSupport.on_load(:action_controller_base) do
        helper Iconmap::IconmapTagsHelper
      end
    end

    initializer "iconmap.rescuable_asset_errors" do |app|
      if defined?(Propshaft)
        app.config.iconmap.rescuable_asset_errors << Propshaft::MissingAssetError
      end

      if defined?(Sprockets::Rails)
        app.config.iconmap.rescuable_asset_errors << Sprockets::Rails::Helper::AssetNotFound
      end
    end
  end
end
