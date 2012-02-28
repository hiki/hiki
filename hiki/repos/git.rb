require 'hiki/repos/default'
require 'English'

module Hiki
  class ReposGit < ReposBase
    include Hiki::Util

    def commit(page, msg = default_msg)
      Dir.chdir("#{@data_path}/text") do
        system("git add -- #{escape(page)}".untaint)
        system("git commit -q -m \"#{msg}\" -- #{escape(page)}".untaint)
      end
    end

    def delete(page, msg = default_msg)
      Dir.chdir("#{@data_path}/text") do
        system("git rm -q -- #{escape(page)}".untaint)
        system("git commit -q -m \"#{msg}\" #{escape(page)}".untaint)
      end
    end

    def rename(old_page, new_page)
      raise NotImplementedError
    end

    def get_revision(page, revision)
      ret = ''
      Dir.chdir("#{@data_path}/text") do
        open("|git cat-file blob #{revision}".untaint) do |f|
          ret = f.read
        end
      end
      ret
    end

    def revisions(page)
      require 'time'
      all_log = ''
      revs = []
      Dir.chdir("#{@data_path}/text") do
        open("|git log --raw -- #{escape(page).untaint}") do |f|
          all_log = f.read
        end
      end
      all_log.split(/^commit (?:[a-fA-F\d]+)\n/).each do |log|
        if /\AAuthor:\s*(.*?)\nDate:\s*(.*?)\n(.*?)
            \n:\d+\s\d+\s[a-fA-F\d]+\.{3}\s([a-fA-F\d]+)\.{3}\s\w
               \s+#{Regexp.escape(escape(page))}\n+\z/xm =~ log
          revs << [$4,
                   Time.parse("#{$2}Z").localtime.strftime('%Y/%m/%d %H:%M:%S'),
                   "", # $1,
                   $3.strip]
        end
      end
      revs
    end
  end
end
