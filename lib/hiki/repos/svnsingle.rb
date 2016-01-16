require 'hiki/repos/svn'

module Hiki
  # The hikifarm has only one repository
  class HikifarmReposSvnsingle < HikifarmReposSvnBase
    def setup
      system("svnadmin create #{@root}")
    end
  end

  class ReposSvnsingle < ReposSvn; end
end
