# Copyright (C) 2003, Koichiro Ohba <koichiro@meadowy.org>
# Copyright (C) 2003, Yasuo Itabashi <yasuo_itabashi{@}hotmail.com>
# You can distribute this under GPL.

require "hiki/repos/default"
require 'sequel'

module Hiki
  class HikifarmReposRdb < HikifarmReposBase
    def initialize(database_url, data_path)
      @database_url = database_url
      @data_path = data_path
    end

    def setup
    end

    def imported?(wiki)
      true
    end

    def import(wiki)
      Sequel.connect(ENV['DATABASE_URL'] || @database_url) do |db|
        Dir["#{@data_path}/#{wiki}/text/*"].each do |f|
          if File.file?(f.untaint)
            db[:page_backup].insert(wiki: wiki, name: File.basename(f), body: File.read(f), last_modified: File.mtime(f), revision: 1)
            db[:page].insert(wiki: wiki, name: File.basename(f), body: File.read(f), last_modified: File.mtime(f))
          end
        end
      end
    end

    def update(wiki)
    end
  end

  class ReposRdb < ReposBase
    attr_writer :db

    def initialize(database_url, data_path)
    end

    def commit(page, msg = default_msg)
    end

    def delete(page, msg = default_msg)
    end

    def get_revision(page, revision)
      db.open_db do
        record = db[:page_backup].where(wiki: db.wiki, name: page, revision: revision).limit(1).select(:body).first
      end

      if record && record[:body]
        record[:body]
      else
        ""
      end
    end

    def revisions(page)
      db.open_db do
        records = db[:page_backup].where(wiki: db.wiki, name: page).order(:revision).select(:revision, :last_modified, :editor)
      end
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
