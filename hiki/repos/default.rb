# $Id: default.rb,v 1.7 2005-07-16 04:24:33 yanagita Exp $
# Copyright (C) 2003, Koichiro Ohba <koichiro@meadowy.org>
# Copyright (C) 2003, Yasuo Itabashi <yasuo_itabashi{@}hotmail.com>
# You can distribute this under GPL.

require 'hiki/util'

module Hiki
  class HikifarmReposBase
    def initialize(root, data_root)
      @root = root
      @data_root = data_root
    end

    def setup
      raise "Please override this function."
    end

    def imported?( wiki )
      raise "Please override this function."
    end

    def import( wiki )
      raise "Please override this function."
    end

    def update( wiki )
      raise "Please override this function."
    end
  end

  class ReposBase
    def initialize(root, data_path)
      @root = root
      @data_path = data_path
      @text_dir = File.join(data_path, "text")
    end

    def commit(page, log = nil)
      raise "Please override this function."
    end

    def commit_with_content(page, content, log = nil)
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

  # Null Repository Backend
  class HikifarmReposDefault < HikifarmReposBase
    def setup
    end

    def imported?(wiki)
      return true
    end

    def import(wiki)
    end

    def update(wiki)
    end
  end

  class ReposDefault < ReposBase
    include Hiki::Util

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
        ''
      end
    end

    def revisions(page)
      rev = []
      rev << [2, File.mtime("#{rev_path(2)}/#{escape(page).untaint}").localtime.strftime('%Y/%m/%d %H:%M:%S'), '', 'current']
      rev << [1, File.mtime("#{rev_path(1)}/#{escape(page).untaint}").localtime.strftime('%Y/%m/%d %H:%M:%S'), '', 'backup'] if File.exist?("#{rev_path(1)}/#{escape(page).untaint}")
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
