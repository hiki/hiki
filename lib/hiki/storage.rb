require "hiki/registry"

module Hiki
  module Storage
    REGISTRY = Registry.new(:storage)
    extend Registry::ClassMethods
  end
end

require "hiki/storage/base"
require "hiki/storage/flatfile"
require "hiki/storage/rdb"
