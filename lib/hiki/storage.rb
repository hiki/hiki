require 'hiki/registry'

module Hiki
  module Storage
    REGISTRY = Hiki::Registry.new(:storage)
  end
end

require "hiki/storage/base"
require "hiki/storage/flatfile"
require "hiki/storage/rdb"
