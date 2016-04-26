require "hiki/repository/base"

module Hiki
  module Repository
    class Git < Base
      include Hiki::Util

      Repository.register(:git, self)

      def commit(page, msg = default_msg)
        escaped_page = escape(page).untaint
        Dir.chdir(@text_dir) do
          system("git add -- #{escaped_page}".untaint)
          system("git commit -q -m \"#{msg.untaint}\" -- #{escaped_page}")
        end
      end

      def commit_with_content(page, content, message = default_msg)
        escaped_page = escape(page).untaint
        File.open(File.join(@text_dir, escaped_page), "w+") do |file|
          file.write(content)
        end
        commit(page)
      end

      def delete(page, msg = default_msg)
        escaped_page = escape(page).untaint
        Dir.chdir(@text_dir) do
          system("git rm -q -- #{escaped_page}")
          system("git commit -q -m \"#{msg.untaint}\" #{escaped_page}")
        end
      end

      def rename(old_page, new_page)
        old_page = escape(old_page.untaint)
        new_page = escape(new_page.untaint)
        Dir.chdir(@text_dir) do
          raise ArgumentError, "#{new_page} has already existed." if File.exist?(new_page)
          system("git", "mv", old_page, new_page)
          system("git", "commit", "-q", "-m", "'Rename #{old_page} to #{new_page}'")
        end
      end

      def get_revision(page, revision)
        ret = ""
        Dir.chdir(@text_dir) do
          open("|git cat-file blob #{revision}".untaint) do |f|
            ret = f.read
          end
        end
        ret
      end

      def revisions(page)
        require "time"
        all_log = ""
        revs = []
        Dir.chdir(@text_dir) do
          open("|git log --raw -- #{escape(page).untaint}") do |f|
            all_log = f.read
          end
        end
        all_log.split(/^commit (?:[a-fA-F\d]+)\n/).each do |log|
          if /\AAuthor:\s*(.*?)\nDate:\s*(.*?)\n(.*?)
              \n:\d+\s\d+\s[a-fA-F\d]+\.{3}\s([a-fA-F\d]+)\.{3}\s\w
                 \s+#{Regexp.escape(escape(page))}\n+\z/xm =~ log
            revs << [$4,
                     Time.parse("#{$2}Z").localtime.strftime("%Y/%m/%d %H:%M:%S"),
                     "", # $1,
                     $3.strip]
          end
        end
        revs
      end
    end
  end
end
