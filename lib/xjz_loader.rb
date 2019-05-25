require "xjz_loader/version"

module XjzLoader
  class Error < StandardError; end

  ROOT = nil

  require_relative '../ext/loader/loader'
end
