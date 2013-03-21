# $Id: svn.rb,v 1.14 2005/09/11 10:10:30 fdiary Exp $
# Copyright (C) 2003, Koichiro Ohba <koichiro@meadowy.org>
# Copyright (C) 2003, Yasuo Itabashi <yasuo_itabashi{@}hotmail.com>
# You can distribute this under GPL.

require "hiki/repos/default"
require "mysql.so"

# Subversion Repository Backend
module Hiki
  class HikifarmReposMysql < HikifarmReposBase
    def initialize(root, data_root)
      @data_root = data_root
      @db = Mysql.real_connect(*(root.split(/,/)))
      @db.query("set names ujis")
    end

    def setup
      # do nothing
    end

    def imported?(wiki)
      return true
    end

    def import(wiki)
      Dir["#{@data_root}/#{wiki}/text/*"].each do |f|
        if File.file?(f.untaint)
          st = @db.prepare('insert into page_backup (wiki, name, body, last_modified, revision) values (?, ?, ?, ?, 1)')
          st.execute(wiki, File.basename(f), File.read(f), File.mtime(f)) 
          st = @db.prepare('insert into page (wiki, name, body, last_modified) values (?, ?, ?, ?)')
          st.execute(wiki, File.basename(f), File.read(f), File.mtime(f)) 
        end
      end
    end

    def update(wiki)
      # do nothing
    end
  end

  class ReposMysql < ReposBase
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
      st = @db.db.prepare("select page_backup.body from page_backup where wiki=? and name=? and revision=?")
      st.execute(@db.wiki, page, revision)
      res = st.fetch
      if res
        body = res.first
        if body.empty?
          return ""
        else
          return body
        end
      else
        return ""
      end
    end

    def revisions(page)
      revs = []
      st = @db.db.prepare("select page_backup.revision, page_backup.last_modified, page_backup.editor from page_backup where wiki=? and name=? order by revision desc")
      st.execute(@db.wiki, page)
      while res = st.fetch
        revision = res[0]
        last_modified = "%04d/%02d/%02d %02d:%02d:%02d" % [res[1].year, res[1].month,
                                               res[1].day, res[1].hour,
                                               res[1].minute, res[1].second]
        editor = res[2] || "Anonymous"
        revs << [revision, last_modified, nil, editor]
      end
      revs
    end
  end
end
