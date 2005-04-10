# $Id: svn.rb,v 1.3 2005-04-10 09:34:54 yanagita Exp $
# Copyright (C) 2003, Koichiro Ohba <koichiro@meadowy.org>
# Copyright (C) 2003, Yasuo Itabashi <yasuo_itabashi{@}hotmail.com>
# You can distribute this under GPL.

require 'hiki/repos/default'
require 'fileutils'

# Subversion Repository Backend
module Hiki
  class ReposSvnBase < ReposDefault
    def setup
    end

    def imported?(wiki)
      s = ''
      open("|svn ls file://#{@root}/#{wiki}") do |f|
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
        system("svn import -m 'Starting #{wiki} from #{ENV['REMOTE_ADDR']} - #{ENV['REMOTE_HOST']}' . file://#{@root}/#{wiki}/trunk > /dev/null 2>&1".untaint)
      end
      Dir.chdir("#{@data_path}/#{wiki}") do
        FileUtils.rm_rf('text')
        system("svn checkout file://#{@root}/#{wiki}/trunk text > /dev/null 2>&1")
        system("svn propdel svn:mime-type -R text > /dev/null 2>&1")
      end
    end

    def update(wiki)
      Dir.chdir("#{@data_path}/#{wiki}/text") do
        system("svn update > /dev/null 2>&1")
      end
    end

    def commit(page)
      Dir.chdir("#{@data_path}/text") do
        system("svn add -- #{page.escape} > /dev/null 2>&1".untaint)
        system("svn propdel svn:mime-type -- #{page.escape} > /dev/null 2>&1".untaint)
        system("svn ci -m '#{ENV['REMOTE_ADDR']} - #{ENV['REMOTE_HOST']}' > /dev/null 2>&1".untaint)
      end
    end

    def delete(page)
      Dir.chdir("#{@data_path}/text") do
        system("svn remove -- #{page.escape} > /dev/null 2>&1".untaint)
        system("svn ci -m '#{ENV['REMOTE_ADDR']} - #{ENV['REMOTE_HOST']}' > /dev/null 2>&1".untaint)
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
      system("svnadmin create #{@root}/#{wiki} > /dev/null 2>&1")
      super
    end
  end

  # The hikifarm has only one repository
  class ReposSvnsingle < ReposSvnBase
    def setup
      system("svnadmin create #{@root} > /dev/null 2>&1")
    end
  end
end
