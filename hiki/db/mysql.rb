# $Id: flatfile.rb,v 1.23 2005/11/01 14:21:00 yanagita Exp $
# Copyright (C) 2007 Kazuhiko <kazuhiko@fdiary.net>

require "mysql.so"
require "hiki/storage"
require "hiki/util"
require "hiki/db/tmarshal"

module Hiki
  class HikiDB_mysql < HikiDBBase
    attr_reader :db, :wiki

    def initialize(conf)
      @conf = conf
      @db = Mysql.real_connect(@conf.database_host, @conf.database_user, @conf.database_pass, @conf.database_name)
      @db.query("set names ujis")
      @wiki = @conf.database_wiki
      @conf.repos.db = self
      @cache = {}
    end

    def close_db
      true
    end

    def store(page, text, md5, update_timestamp = true)
      if exist?(page)
        return nil if md5 != md5hex(page)
        if update_timestamp
          backup(page)
        end
      end

      body = text
      last_modified = Time::now
      st = @db.prepare("insert into page_backup (body, last_modified, wiki, name, revision) select ?,?,?,?,ifnull(max(revision), 0) + 1 from page_backup where wiki=? and name=?")
      st.execute(body, last_modified, @wiki, page, @wiki, page)
      if update_timestamp
        st = @db.prepare("insert into page (body, last_modified, wiki, name, count) values (?,?,?,?,0) on duplicate key update body=?,last_modified=?")
        st.execute(body, last_modified, @wiki, page, body, last_modified)
      else
        st = @db.prepare("insert into page (body, last_modified, wiki, name, count) values (?,?,?,?,0) on duplicate key update body=?")
        st.execute(body, last_modified, @wiki, page, body)
      end
      @cache[page] = body
      true
    end

    def unlink(page)
      st = @db.prepare("delete from page where wiki=? and name=?")
      st.execute(@wiki, page)
    end

    def load(page)
      return @cache[page] if @cache.has_key?(page)
      st = @db.prepare("select page.body from page where wiki=? and name=?")
      st.execute(@wiki, page)
      res = st.fetch
      if res
        body = res.first
        if body.empty?
          body = nil
        end
      else
        body = nil
      end
      @cache[page] = body
      return body
    end

    def load_backup(page)
      st = @db.prepare("select page_backup.body from page_backup where wiki=? and name=? order by revision desc limit 1 offset 1")
      st.execute(@wiki, page)
      res = st.fetch
      if res
        return res.first.to_euc
      else
        return nil
      end
    end

    def save(page, src, md5)
      raise "DB#save is obsoleted. Please use Plugin#save instead."
    end

    def exist?(page)
      return  page_info.find{|i| i.to_a[0][0] == page} ? true : false
    end

    def pages
      ret = []
      st = @db.prepare("select page.name from page where wiki=?")
      st.execute(@wiki)
      while res = st.fetch
        ret << res.first
      end
      return ret
    end

    # ==============
    #   info DB
    # ==============
    def info(page)
      res = page_info.find{|i| i.to_a[0][0] == page}.to_a[0][1] rescue nil
      if res
        return res
      else
        return default
      end
    end

    def page_info
      return @info_db if @info_db
      ret = []
      st = @db.prepare("select page.name, page.title, page.last_modified, page.keyword, page.references, page.editor, page.freeze, page.count from page where wiki=?")
      st.execute(@wiki)
      while res = st.fetch
        name = res.shift
        ret << {name => make_info_hash(res)}
      end
      @info_db = ret
      return ret
    end

    def set_attribute(page, attr)
      attr.each do |attribute, value|
	attribute = attribute.to_s.chomp
        case value
        when Array
          value = value.join("\n")
        when TrueClass
          value = 1
        when FalseClass
          value = 0
        end
        st = @db.prepare("update page set page.#{attribute}=? where wiki=? and name=?")
        st.execute(value, @wiki, page)
	if !["references", "count", "freeze"].include?(attribute)
          st2 = @db.prepare("update page_backup set page_backup.#{attribute}=? where wiki=? and name=? order by revision desc limit 1")
          st2.execute(value, @wiki, page)
        end
      end
    end

    def get_attribute(page, attribute)
      return info(page)[attribute]
    end

    def select
      result = []
      page_info.each do |e|
        name, info = e.to_a.first
        result << name if yield(info)
      end
      result
    end

    def increment_hitcount (page)
      st = @db.prepare("update page set count=count+1 where wiki=? and name=?")
      st.execute(@wiki, page)
    end

    def get_hitcount(page)
      get_attribute(page, :count)
    end

    def freeze_page (page, freeze)
      set_attribute(page, [[:freeze, freeze]])
    end

    def is_frozen? (page)
      get_attribute(page, :freeze)
    end

    def set_last_update (page, t)
      set_attribute(page, [[:last_modified, t]])
    end

    def get_last_update(page)
      get_attribute(page, :last_modified)
    end

    def set_references(page, r)
      set_attribute(page, [[:references, r]])
    end

    def get_references(page)
      ref = []
      page_info.each do |a|
        r = a.values[0][:references]
        if String === r # for compatibility
          r = r.split(",")
          set_references(a.keys[0], r)
        end
        ref << a.keys[0] if r.include?(page)
      end
      ref
    end

  private
    def create_missing_dirs
      [@pages_path, @backup_path].each {|d|
        FileUtils.mkdir_p(d) unless FileTest.exist?(d)
      }
    end

    def default
      { :count          => 0,
        :last_modified  => Time::now,
        :freeze         => false,
        :references     => [],
        :keyword        => [],
        :title          => "",
      }
    end

    def make_info_hash(ary)
      return {:title => ary[0] || "",
        :last_modified  => make_time(ary[1]),
        :keyword => (ary[2] || "").split(/\n/),
        :references => (ary[3] || "").split(/\n/),
        :editor => ary[4],
        :freeze => ary[5] == 1,
        :count => ary[6],
      }
    end

    def make_time(mysql_time)
      if mysql_time
        return Time::local(mysql_time.year, mysql_time.month, mysql_time.day,
                          mysql_time.hour, mysql_time.minute, mysql_time.second)
      else
        return Time::now
      end
    end

    def textdir(s)
      File::join(@pages_path, s.escape).untaint
    end

    def backupdir(s)
      File::join(@backup_path, s.escape).untaint
    end
  end
end
