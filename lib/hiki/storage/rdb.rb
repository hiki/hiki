require "hiki/storage/base"
require "hiki/util"
require "tmarshal"
require "sequel"

module Hiki
  module Storage
    class RDB < Base
      Storage.register(:rdb, self)

      attr_reader :db, :wiki

      def initialize(conf)
        @conf = conf
        @wiki = @conf.database_wiki
        @cache = {}

        @conf.repos.db = self
      end

      def open_db
        if block_given?
          begin
            @db = Sequel.connect(ENV["DATABASE_URL"] || @conf.database_url)
            yield
          ensure
            close_db
          end
        else
          true
        end
        true
      end

      def close_db
        @db.disconnect
      end

      def store(page, body, md5, update_timestamp = true)
        if exist?(page)
          return nil if md5 != md5hex(page)
          if update_timestamp
            backup(page)
          end
        end

        last_modified = Time::now

        revisions = @db[:page_backup].where(wiki: @wiki, name: page).select(:revision).to_a.map{|record| record[:revision]}
        revision = revisions.empty? ? 1 : revisions.max + 1
        @db[:page_backup].insert(body: body, last_modified: last_modified, wiki: @wiki, name: page, revision: revision)

        record = @db[:page].where(wiki: @wiki, name: page)
        if record.first
          record.update(body: body, last_modified: last_modified)
        else
          @db[:page].insert(body: body, last_modified: last_modified, wiki: @wiki, name: page, count: 0)
        end

        @cache[page] = body
        true
      end

      def unlink(page)
        @db[:page].where(wiki: @wiki, name: page).delete
      end

      def load(page)
        return @cache[page] if @cache.has_key?(page)

        if res = @db[:page].where(wiki: @wiki, name: page).limit(1).select(:body).first
          @cache[page] = res[:body]
        else
          @cache[page] = nil
        end
        @cache[page]
      end

      def load_backup(page)
        if res = @db[:page_backup].where(wiki: @wiki, name: page).order(:revision).limit(1).select(:body).first
          res[:body]
        else
          nil
        end
      end

      def save(page, src, md5)
        raise "DB#save is obsoleted. Please use Plugin#save instead."
      end

      def exist?(page)
        return  page_info.find{|i| i.to_a[0][0] == page} ? true : false
      end

      def pages
        @db[:page].where(wiki: @wiki).select(:name).to_a.map{|page| page[:name]}
      end

      def info(page)
        res = page_info.find{|i| i.to_a[0][0] == page}.to_a[0][1] rescue nil
        if res
          return res
        else
          return default
        end
      end

      def page_info
        @info_db ||= @db[:page].where(wiki: @wiki).select(:name, :title, :last_modified, :keyword, :references, :editor, :freeze, :count).to_a.map{|page| {page[:name] => make_info_hash(page)}}
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
          @db[:page].where(wiki: @wiki, name: page).update(attribute => value)
          unless %w(references count freeze).include?(attribute)
            @db[:page_backup].where(wiki: @wiki, name: page).reverse_order(:revision).limit(1).update(attribute => value)
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

      def increment_hitcount(page)
        @db[:page].where(wiki: @wiki, name: page).update(count: count + 1)
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
        { count: 0,
          last_modified: Time::now,
          freeze: false,
          references: [],
          keyword: [],
          title: "",
        }
      end

      def make_info_hash(hash)
        {
          title: hash[:title] || "",
          last_modified: make_time(hash[:last_modified]),
          keyword: (hash[:keyword] || "").split(/\n/),
          references: (hash[:references] || "").split(/\n/),
          editor: hash[:editor],
          freeze: (hash[:freeze] == 1),
          count: hash[:count],
        }
      end

      def make_time(time)
        if time
          Time.local(time.year, time.month, time.day, time.hour, time.min, time.sec)
        else
          Time.now
        end
      end

      def textdir(s)
        File::join(@pages_path, escape(s)).untaint
      end

      def backupdir(s)
        File::join(@backup_path, escape(s)).untaint
      end
    end
  end
end
