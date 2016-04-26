# Copyright (C) 2008, KURODA Hiraku <hiraku{@}hinet.mydns.jp>
# This code is modified from "hiki/repos/git.rb" by Kouhei Sutou
# You can distribute this under GPL.

require "hiki/repository/base"

module Hiki
  module Repository
    class Hg < Base
      include Hiki::Util

      Repository.register(:hg, self)

      def commit(page, msg = default_msg)
        escaped_page = escape(page).untaint
        Dir.chdir(@text_dir) do
          system("hg addremove -q #{escaped_page}")
          system("hg ci -m \"#{msg}\" #{escaped_page}")
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
          system("hg rm #{escaped_page}")
          system("hg ci -m \"#{msg}\" #{escaped_page}")
        end
      end

      def rename(old_page, new_page)
        old_page = escape(old_page.untaint)
        new_page = escape(new_page.untaint)
        Dir.chdir(@text_dir) do
          raise ArgumentError, "#{new_page} has already existed." if File.exist?(new_page)
          system("hg", "mv", "-q", old_page, new_page)
          system("hg", "commit", "-q", "-m", "'Rename #{old_page} to #{new_page}'")
        end
      end

      def get_revision(page, revision)
        r = ""
        escaped_page = escape(page).untaint
        Dir.chdir(@text_dir) do
          open("|hg cat -r #{revision.to_i-1} #{escaped_page}".untaint) do |f|
            r = f.read
          end
        end
        r
      end

      def revisions(page)
        require "time"
        escaped_page = escape(page).untaint
        all_log = ""
        revs = []
        original_lang = ENV["LANG"]
        ENV["LANG"] = "C"
        Dir.chdir(@text_dir) do
          open("|hg log #{escaped_page}") do |f|
            all_log = f.read
          end
        end
        ENV["LANG"] = original_lang
        all_log.split(/\n\n(?=changeset:\s+\d+:)/).each do |l|
          rev = l[/^changeset:\s+(\d+):.*$/, 1].to_i+1
          date = Time.parse(l[/^date:\s+(.*)$/, 1]).localtime.strftime("%Y/%m/%d %H:%M:%S")
          summary = l[/^summary:\s+(.*)$/, 1]
          revs << [rev, date, "", summary]
        end
        revs
      end
    end
  end
end
