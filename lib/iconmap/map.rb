# frozen_string_literal: true

require 'pathname'

class Iconmap::Map
  attr_reader :packages

  class InvalidFile < StandardError; end

  def initialize
    @packages = {}
    @cache = {}
  end

  def draw(path = nil, &)
    if path && File.exist?(path)
      begin
        instance_eval(File.read(path), path.to_s)
      rescue StandardError => e
        Rails.logger.error "Unable to parse icon map from #{path}: #{e.message}"
        raise InvalidFile, "Unable to parse icon map from #{path}: #{e.message}"
      end
    elsif block_given?
      instance_eval(&)
    end

    self
  end

  def pin(name)
    clear_cache
    @packages[name] = MappedFile.new(name: name)
  end

  # Returns an instance of ActiveSupport::EventedFileUpdateChecker configured to clear the cache of the map
  # when the directories passed on initialization via `watches:` have changes. This is used in development
  # and test to ensure the map caches are reset when icon files are changed.
  def cache_sweeper(watches: nil)
    if watches
      @cache_sweeper =
        Rails.application.config.file_watcher.new([], Array(watches).collect { |dir| [dir.to_s, 'svg'] }.to_h) do
          clear_cache
        end
    else
      @cache_sweeper
    end
  end

  private

  MappedFile = Struct.new(:name, keyword_init: true)

  def clear_cache
    @cache.clear
  end
end
