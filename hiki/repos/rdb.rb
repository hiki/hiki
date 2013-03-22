# $Id: svn.rb,v 1.14 2005/09/11 10:10:30 fdiary Exp $
# Copyright (C) 2003, Koichiro Ohba <koichiro@meadowy.org>
# Copyright (C) 2003, Yasuo Itabashi <yasuo_itabashi{@}hotmail.com>
# You can distribute this under GPL.

require "hiki/repos/default"
require 'sequel'

module Hiki
  class HikifarmReposRdb < HikifarmReposBase
    def initialize(root, data_root)
      @data_root = data_root
      @db = Sequel.connect(root)
    end

    def setup
      # do nothing
    end

    def imported?(wiki)
      true
    end

    def import(wiki)
      Dir["#{@data_root}/#{wiki}/text/*"].each do |f|
        if File.file?(f.untaint)
          @db[:page_backup].insert(wiki: wiki, name: File.basename(f), body: File.read(f), last_modified: File.mtime(f), revision: 1)
          @db[:page].insert(wiki: wiki, name: File.basename(f), body: File.read(f), last_modified: File.mtime(f))
        end
      end
    end

    def update(wiki)
      # do nothing
    end
  end

  class ReposRdb < ReposBase
    attr_writer :db

    def initialize(root, data_path)
      # do nothing
    end

    def commit(page, msg = default_msg)
      # do nothing
    end

    def delete(page, msg = default_msg)
      # do nothing
    end

    def get_revision(page, revision)
      record = @db.db[:page_backup].where(wiki: @db.wiki, name: page, revision: revision).select(:body).first
      if record && record[:body]
        record[:body]
      else
        ""
      end
    end

    def revisions(page)
      records = @db.db[:page_backup].where(wiki: @db.wiki, name: page).order(:revision).select(:revision, :last_modified, :editor)
      records.map do |record|
        [
          record[:revision],
          "%04d/%02d/%02d %02d:%02d:%02d" % [record[:last_modified].year, record[:last_modified].month, record[:last_modified].day, record[:last_modified].hour, record[:last_modified].min, record[:last_modified].sec],
          nil,
          record[:editor] || "Anonymous"
        ]
      end
    end
  end
end
