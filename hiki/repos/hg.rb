# $Id: hg.rb,v 1.1 2008-08-06 10:48:25 hiraku Exp $
# Copyright (C) 2008, KURODA Hiraku <hiraku{@}hinet.mydns.jp>
# This code is modified from "hiki/repos/git.rb" by Kouhei Sutou
# You can distribute this under GPL.

require 'hiki/repos/default'

module Hiki
  class ReposHg < ReposBase
    def commit(page, msg = default_msg)
      Dir.chdir("#{@data_path}/text") do
        system("hg addremove -q #{page.escape}".untaint)
        system("hg ci -m \"#{msg}\" #{page.escape}".untaint)
      end
    end

    def delete(page, msg = default_msg)
      Dir.chdir("#{@data_path}/text") do
        system("hg rm #{page.escape}".untaint)
        system("hg ci -m \"#{msg}\" #{page.escape}".untaint)
      end
    end

    def get_revision(page, revision)
      r = ""
      Dir.chdir("#{@data_path}/text") do
        open("|hg cat -r #{revision.to_i-1} #{page.escape}".untaint) do |f|
          r = f.read
        end
      end
      r
    end

    def revisions(page)
      require 'time'
      all_log = ''
      revs = []
      Dir.chdir("#{@data_path}/text") do
        open("|hg log #{page.escape.untaint}") do |f|
          all_log = f.read
        end
      end
      all_log.split(/\n\n(?=changeset:\s+\d+:)/).each do |l|
	rev = l[/^changeset:\s+(\d+):.*$/, 1].to_i+1
	date = Time.parse(l[/^date:\s+(.*)$/, 1]).localtime.strftime('%Y/%m/%d %H:%M:%S')
	summary = l[/^summary:\s+(.*)$/, 1]
        revs << [rev, date, "", summary]
      end
      revs
    end
  end
end
