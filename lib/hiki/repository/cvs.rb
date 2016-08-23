# Copyright (C) 2003, Koichiro Ohba <koichiro@meadowy.org>
# Copyright (C) 2003, Yasuo Itabashi <yasuo_itabashi{@}hotmail.com>
# You can distribute this under GPL.

require "hiki/repository/base"

module Hiki
  module Repository
    class CVS < Base
      include Hiki::Util

      Hiki::Repository.register(:cvs, self)

      def commit(page, msg = default_msg)
        Dir.chdir("#{@data_path}/text") do
          system("cvs -d #{@root} add -- #{escape(page)} > /dev/null 2>&1".untaint)
          system("cvs -d #{@root} ci -m '#{msg}' > /dev/null 2>&1".untaint)
        end
      end

      def delete(page, msg = default_msg)
        Dir.chdir("#{@data_path}/text") do
          system("cvs -d #{@root} remove -- #{escape(page)} > /dev/null 2>&1".untaint)
          system("cvs -d #{@root} ci -m '#{msg}' > /dev/null 2>&1".untaint)
        end
      end

      def rename(old_page, new_page)
        raise NotImplementedError
      end

      def get_revision(page, revision)
        ret = ""
        Dir.chdir("#{@data_path}/text") do
          open("|cvs -Q up -p -r 1.#{revision.to_i} #{escape(page).untaint}") do |f|
            ret = f.read
          end
        end
        ret
      end

      def revisions(page)
        require "time"
        log = ""
        revs = []
        Dir.chdir("#{@data_path}/text") do
          open("|cvs -Q log #{escape(page).untaint}") do |f|
            log = f.read
          end
        end
        log.split(/----------------------------/).each do |tmp|
          if /revision 1.(\d+?)\ndate: (.*?);  author: (?:.*?);  state: (?:.*?);(.*?)?(?:;.*?)?\n(.*)/m =~ tmp then
            revs << [$1.to_i, Time.parse("#{$2}Z").localtime.to_s, $3, $4.chomp]
          end
        end
        revs
      end
    end
  end
end
