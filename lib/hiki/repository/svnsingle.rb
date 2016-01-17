require "hiki/repository/svn"

module Hiki
  module Repository
    class SVNSingle < SVN
      Hiki::Config::REPOSITORY_REGISTRY[:svnsingle] = self
    end
  end
end
