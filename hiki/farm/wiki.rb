require 'hiki/util'

module Hiki
  module Farm
    class Wiki
      include ::Hiki::Util

      attr_reader :name, :title, :mtime, :last_modified_page, :pages_num, :pages

      def initialize(name, data_root)
        @name = name
        @pages_num = 0

        begin
          File.readlines("#{data_root}/#{name}/hiki.conf").each do |line|
            if /^[@\$]?site_name\s*=\s*(".*")\s*$/ =~ line
              @title = eval($1.untaint)
            end
          end
        rescue
          @title = "#{name}'s Wiki"
        end

        pages = Dir["#{data_root}/#{name}/text/*"]
        pages.delete_if{|f|
          File.basename(f) == 'CVS' or File.basename(f) == '.svn' or File.size?(f.untaint).nil?
        }
        pages = pages.sort_by{|f| File.mtime(f) }
        if pages.empty?
          @last_modified_page = "FrontPage"
          @mtime = Time.at(0)
        else
          @last_modified_page = File.basename(pages[-1])
          @mtime = File.mtime(pages[-1])
        end
        @pages_num = pages.size
        @pages = pages.reverse[0..9].collect do |page|
          {
            name: File.basename(page),
            mtime: File.mtime(page),
          }
        end
      end

      def description
        "#{unescape(last_modified_page)} was updated."
      end
    end
  end
end
