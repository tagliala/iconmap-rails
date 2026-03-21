# frozen_string_literal: true

class Iconmap::Reloader
  delegate :execute_if_updated, :execute, :updated?, to: :updater

  def reload!
    iconmap_paths.each { |path| Rails.application.iconmap.draw(path) }
  end

  private

  def updater
    @updater ||= config.file_watcher.new(iconmap_paths) { reload! }
  end

  def iconmap_paths
    config.iconmap.paths
  end

  def config
    Rails.application.config
  end
end
