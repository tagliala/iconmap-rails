require "active_support"
require "active_support/core_ext/module/delegation"

class Iconmap::Reloader
  delegate :execute_if_updated, :execute, :updated?, to: :updater

  def reload!
    icon_map_paths.each { |path| Rails.application.iconmap.draw(path) }
  end

  private
    def updater
      @updater ||= config.file_watcher.new(icon_map_paths) { reload! }
    end

    def icon_map_paths
      config.iconmap.paths
    end

    def config
      Rails.application.config
    end
end
