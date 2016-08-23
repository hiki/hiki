# Copyright (C) 2003, Koichiro Ohba <koichiro@meadowy.org>
# Copyright (C) 2003, Yasuo Itabashi <yasuo_itabashi{@}hotmail.com>
# You can distribute this under GPL.

require "hiki/repository/base"

module Hiki
  module Repository
    class Default < Base
      include Hiki::Util

      Repository.register(:default, self)

      def commit(page, log = nil)
      end

      def commit_with_content(page, content, log = nil)
      end

      def delete(page, log = nil)
      end

      def rename(old_page, new_page)
      end

      def get_revision(page, revision)
        revision = revision.to_i
        begin
          File::read("#{rev_path(revision)}/#{escape(page).untaint}")
        rescue
          ""
        end
      end

      def revisions(page)
        rev = []
        rev << [2, File.mtime("#{rev_path(2)}/#{escape(page).untaint}").localtime.strftime("%Y/%m/%d %H:%M:%S"), "", "current"]
        rev << [1, File.mtime("#{rev_path(1)}/#{escape(page).untaint}").localtime.strftime("%Y/%m/%d %H:%M:%S"), "", "backup"] if File.exist?("#{rev_path(1)}/#{escape(page).untaint}")
        rev
      end

      private

      def rev_path(revision)
        case revision
        when 2
          "#{@data_path}/text"
        when 1
          "#{@data_path}/backup"
        end
      end
    end
  end
end
