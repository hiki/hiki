# $Id: svn.rb,v 1.14 2005-09-11 10:10:30 fdiary Exp $
# Copyright (C) 2003, Koichiro Ohba <koichiro@meadowy.org>
# Copyright (C) 2003, Yasuo Itabashi <yasuo_itabashi{@}hotmail.com>
# You can distribute this under GPL.

require 'hiki/repos/default'
require 'fileutils'

# Subversion Repository Backend
module Hiki
  class HikifarmReposSvnBase < HikifarmReposBase
    def initialize(root, data_root)
      super
      if /^[a-z]:/i =~ @root
        @base_uri = "file:///#{@root}"
      else
        @base_uri = "file://#{@root}"
      end
      @base_uri += '/' if %r|/$| !~ @base_uri
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
      Dir.chdir("#{@data_root}/#{wiki}/text") do
        system("svn import -q -m \"Starting #{wiki} from #{ENV['REMOTE_ADDR']} - #{ENV['REMOTE_HOST']}\" . #{@base_uri}#{wiki}/trunk".untaint)
      end
      Dir.chdir("#{@data_root}/#{wiki}") do
        FileUtils.rm_rf('text')
        system("svn checkout -q #{@base_uri}#{wiki}/trunk text")
        system("svn propdel -q svn:mime-type -R text")
      end
    end

    def update(wiki)
      Dir.chdir("#{@data_root}/#{wiki}/text") do
        system("svn update -q")
      end
    end
  end

  # Independent repositories for each wiki
  class HikifarmReposSvn < HikifarmReposSvnBase
    def setup
      begin
        Dir.mkdir(@root)
      rescue
      end
    end

    def import(wiki)
      system("svnadmin create #{@root}/#{wiki}")
      super
    end
  end

  class ReposSvn < ReposBase
    def initialize(root, data_path)
      super
      if /^[a-z]:/i =~ @root
        @base_uri = "file:///#{@root}"
      else
        @base_uri = "file://#{@root}"
      end
      @base_uri += '/' if %r|/$| !~ @base_uri
    end

    def commit(page, msg = default_msg)
      Dir.chdir("#{@data_path}/text") do
        system("svn add -q -- #{page.escape}".untaint)
        system("svn propdel -q svn:mime-type -- #{page.escape}".untaint)
        system("svn ci -q --force-log -m \"#{msg}\"".untaint)
      end
    end

    def delete(page, msg = default_msg)
      Dir.chdir("#{@data_path}/text") do
        system("svn remove -q -- #{page.escape}".untaint)
        system("svn ci -q --force-log -m \"#{msg}\"".untaint)
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
end
