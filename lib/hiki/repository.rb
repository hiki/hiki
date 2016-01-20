require 'hiki/registry'

module Hiki
  module Repository
    REGISTRY = Hiki::Registry.new(:repository)
  end
end

require 'hiki/repository/base'
require 'hiki/repository/default'
require 'hiki/repository/cvs'
require 'hiki/repository/git'
require 'hiki/repository/hg'
require 'hiki/repository/plain'
require 'hiki/repository/rdb'
require 'hiki/repository/svn'
require 'hiki/repository/svnsingle'
