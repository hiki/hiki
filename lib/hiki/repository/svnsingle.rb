require "hiki/repository/svn"

module Hiki
  module Repository
    class SVNSingle < SVN
      REGISTRY[:svnsingle] = self
    end
  end
end
