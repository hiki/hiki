# $Id: svn.rb,v 1.6 2005-06-16 06:04:03 fdiary Exp $
# Copyright (C) 2003, Koichiro Ohba <koichiro@meadowy.org>
# Copyright (C) 2003, Yasuo Itabashi <yasuo_itabashi{@}hotmail.com>
# You can distribute this under GPL.

require 'hiki/repos/default'
require 'fileutils'

# Subversion Repository Backend
module Hiki
  class ReposSvnBase < ReposDefault
    def initialize(root, data_path)
      super
      if /^[a-z]:/i =~ @repos_root
	@win = true
	@base_uri = "file:///#{@root}/"
	@nullify = '> NUL 2>&1'
      else
	@win = false
	@base_uri = "file://#{@root}/"
	@nullify = '> /dev/null 2>&1'
      end
    end

    def imported?(wiki)
      s = ''
      open("|svn ls #{@base_uri}#{wiki}") do |f|
        s << (f.gets( nil ) ? $_ : '')
      end

      if %r|^trunk/$| =~ s then
        return true
      else
        return false
      end
    end

    def import(wiki)
      Dir.chdir("#{@data_path}/#{wiki}/text") do
        system("svn import -m \"Starting #{wiki} from #{ENV['REMOTE_ADDR']} - #{ENV['REMOTE_HOST']}\" . #{@base_uri}#{wiki}/trunk #{@nullify}".untaint)
      end
      Dir.chdir("#{@data_path}/#{wiki}") do
        FileUtils.rm_rf('text')
        system("svn checkout #{@base_uri}#{wiki}/trunk text #{@nullify}")
        system("svn propdel svn:mime-type -R text #{@nullify}")
      end
    end

    def update(wiki)
      Dir.chdir("#{@data_path}/#{wiki}/text") do
        system("svn update #{@nullify}")
      end
    end

    def commit(page, msg = default_msg)
      Dir.chdir("#{@data_path}/text") do
        system("svn add -- #{page.escape} #{@nullify}".untaint)
        system("svn propdel svn:mime-type -- #{page.escape} #{@nullify}".untaint)
        system("svn ci -m \"#{msg}\" #{@nullify}".untaint)
      end
    end

    def delete(page, msg = default_msg)
      Dir.chdir("#{@data_path}/text") do
        system("svn remove -- #{page.escape} #{@nullify}".untaint)
        system("svn ci -m \"#{msg}\" #{@nullify}".untaint)
      end
    end
  end


  # Independent repositories for each wiki
  class ReposSvn < ReposSvnBase
    def setup
      begin
        Dir.mkdir(@root)
      rescue
      end
    end

    def import(wiki)
      system("svnadmin create #{@root}/#{wiki} #{@nullify}")
      super
    end
  end

  # The hikifarm has only one repository
  class ReposSvnsingle < ReposSvnBase
    def setup
      system("svnadmin create #{@root} #{@nullify}")
    end
  end
end
