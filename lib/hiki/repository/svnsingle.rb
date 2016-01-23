require "hiki/repository/svn"

module Hiki
  module Repository
    class SVNSingle < SVN
      Repository.register(:svnsingle, self)
    end
  end
end
