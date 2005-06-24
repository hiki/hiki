require 'hiki/repos/svn'

module Hiki
  # The hikifarm has only one repository
  class ReposSvnsingle < ReposSvnBase
    def setup
      system("svnadmin create #{@root}")
    end
  end
end
