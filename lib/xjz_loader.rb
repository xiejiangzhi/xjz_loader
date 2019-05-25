require "xjz_loader/version"

module XjzLoader
  class Error < StandardError; end

  class << self
    attr_writer :root

    def root
      return @root if @root && Dir.exist?(@root)
      raise "root is empty, please call XjzLoader.root= to set a root dir"
    end
  end

  require_relative '../ext/loader'
end
