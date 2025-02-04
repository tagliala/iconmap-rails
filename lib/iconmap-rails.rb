module Iconmap
end

require_relative "iconmap/version"
require_relative "iconmap/reloader"
require_relative "iconmap/engine" if defined?(Rails::Railtie)
