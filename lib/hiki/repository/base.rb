require "hiki/util"

module Hiki
  module Repository
    class Base
      def initialize(root, data_path)
        @root = root
        @data_path = data_path
        @text_dir = File.join(data_path, "text")
      end

      def commit(page, log = nil)
        raise "Please override this function."
      end

      def delete(page, log = nil)
        raise "Please override this function."
      end

      def rename(old_page, new_page)
        raise "Please override this function."
      end

      def get_revision(page, revision)
        raise "Please override this function."
      end

      def revisions(page)
        raise "Please override this function."
      end

      def pages
        entries = Dir.entries(File.join(@data_path, "text")).reject{|entry|
          entry =~ /\A\./ || File.directory?(entry)
        }.map{|entry| unescape(entry).b }
        if block_given?
          entries.each do |entry|
            yield entry
          end
        else
          entries
        end
      end

      private

      def default_msg
        "#{ENV['REMOTE_ADDR']} - #{ENV['REMOTE_HOST']}"
      end
    end
  end
end
