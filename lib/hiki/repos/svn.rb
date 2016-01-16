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
    include Hiki::Util

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
      escaped_page = escape(page).untaint
      Dir.chdir(@text_dir) do
        found = system("svn status -q -- #{escaped_page} | grep -q #{escaped_page}")
        system("svn add -q -- #{escaped_page}") unless found
        system("svn propdel -q svn:mime-type -- #{escaped_page}")
        system("svn ci -q --force-log -m \"#{msg}\"")
      end
    end

    def commit_with_content(page, content, msg = default_msg)
      escaped_page = escape(page).untaint
      File.open(File.join(@text_dir, escaped_page), "w+") do |file|
        file.write(content)
      end
      commit(page)
    end

    def delete(page, msg = default_msg)
      escaped_page = escape(page).untaint
      Dir.chdir(@text_dir) do
        system("svn remove -q -- #{escaped_page}")
        system("svn ci -q --force-log -m \"#{msg}\"".untaint)
      end
    end

    def rename(old_page, new_page)
      old_page = escape(old_page.untaint)
      new_page = escape(new_page.untaint)
      Dir.chdir(@text_dir) do
        raise ArgumentError, "#{new_page} has already existed." if File.exist?(new_page)
        system("svn", "mv", "-q", old_page, new_page)
        system("svn", "commit", "-q", "-m", "'Rename #{old_page} to #{new_page}'")
      end
    end

    def get_revision(page, revision)
      ret = ''
      escaped_page = escape(page).untaint
      Dir.chdir(@text_dir) do
        open("|svn cat -r #{revision.to_i} #{escaped_page}") do |f|
          ret = f.read
        end
      end
      ret
    end

    def revisions(page)
      require 'time'
      escaped_page = escape(page).untaint
      log = ''
      revs = []
      Dir.chdir(@text_dir) do
        open("|svn log #{escaped_page}") do |f|
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
