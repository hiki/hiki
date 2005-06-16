# $Id: svn.rb,v 1.8 2005-06-16 09:06:38 fdiary Exp $
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

    def get_revision(page, revision)
      ret = ''
      Dir.chdir("#{@data_path}/text") do
	open("|svn cat -r #{revision.to_i} #{page.escape.untaint}") do |f|
	  ret = f.read
	end
      end
      ret
    end

    def revisions(page)
      require 'time'
      log = ''
      revs = []
      Dir.chdir("#{@data_path}/text") do
        open("|svn log #{page.escape.untaint}") do |f|
          log = f.read
        end
      end
      log.split(/------------------------------------------------------------------------/).each do |tmp|
        if /(?:\D+)(\d+?)[\s:\|]+[(?:\s)*](?:.*?) \| (.*?)(?: \(.+\))? \| (.*?)\n\n(.*?)\n/m =~ tmp then
          revs << [$1.to_i, Time.parse("#{$2}Z").localtime.strftime('%Y/%m/%d %H:%M:%S'), $3, $4]
        end
      end
      revs
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
end
