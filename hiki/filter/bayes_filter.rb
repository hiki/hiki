# Copyright (C) 2008, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2. 

require "fileutils"
require "hiki/filter/bayes_filter/bayes.rb"

module Hiki::Filter
  module BayesFilter
    @@hiki_conf = nil

    module Key
      PREFIX = "bayes_filter"
      THRESHOLD = "#{PREFIX}.threshold"
      THRESHOLD_HAM = "#{PREFIX}.threshold_ham"
      TYPE = "#{PREFIX}.type"
      USE = "#{PREFIX}.use"
      REPORT = "#{PREFIX}.report"
      SHARED_DB_PATH = "#{PREFIX}.shared_db_path"
      SHARE_DB = "#{PREFIX}.share_db"
      LIMIT_OF_SUBMITTED_PAGES = "#{PREFIX}.limit_of_submitted_pages"
    end

    def self.init(conf)
      @@hiki_conf = conf      
      @db = nil
      self
    end

    def self.threshold
      (@@hiki_conf[Key::THRESHOLD] || "0.9").to_f
    end

    def self.threshold_ham
      (@@hiki_conf[Key::THRESHOLD_HAM] || "0.1").to_f
    end

    def self.db_shared?
      @@hiki_conf[Key::SHARED_DB_PATH] and @@hiki_conf[Key::SHARE_DB]
    end

    def self.data_path
      db_shared? ? @@hiki_conf[Key::SHARED_DB_PATH] : @@hiki_conf.data_path
    end

    def self.db_name
      "#{data_path}/bayes.db"
    end

    def self.db
      case @@hiki_conf["bayes_filter.type"]
      when /graham/i
        @db ||= Bayes::PaulGraham.new(db_name)
      else
        @db ||= Bayes::PlainBayes.new(db_name)
      end
      @db
    end

    def self.new_db
      FileUtils.rm_f(db_name)
      @db = nil
      db
    end

    def self.cache_path
      r = db_shared? ? "#{data_path}/cache/bayes" : "#{@@hiki_conf.cache_path}/bayes"
      FileUtils.mkpath(r)
      r
    end

    def self.filter(new_page, old_page, posted_by_user)
      pd = PageData.new(new_page, old_page)

      if posted_by_user
        unless pd.ham?
          token = pd.token
          db.ham << token
          10.times do
            break if pd.ham?
            db.ham << token
          end
          db.save
        end
        return
      end

      pd.cache_save

      subject = "#{REPORT_PREFIX[pd.ham?]} at '#{new_page.page}' of '#{@@hiki_conf.site_name}'"
      body = <<EOT
URL               : #{pd.url}
Page              : #{new_page.page}
Address           : #{new_page.remote_addr}
Title             : #{new_page.title}
Appended keywords : #{pd.diff_keyword.sort.join(", ")}
Appended text----
#{pd.diff_text}
----
EOT

      Hiki::Filter.plugin.sendmail(subject, body) if @@hiki_conf[Key::REPORT]
      !pd.ham?
    end

    class TokenList < Bayes::TokenList
      def initialize
        super(Bayes::CHARSET::EUC)
      end

      RE_URL = %r[(?:https?|ftp)://[a-zA-Z0-9;/?:@&=+$,\-_.!~*\'()%]+]
      def add_text(text)
        text = text.dup
        text.gsub!(RE_URL) do |m|
          add_url(m, "U")
          ""
        end
        add_message(text)

        self
      end
    end

    class PageData
      include BayesFilter
      attr_reader :time, :new_page, :old_page

      def initialize(new_page, old_page=Hiki::Filter::PageData.new, time=Time.now)
        @index_url = @@hiki_conf.index_url
        @new_page = new_page
        @old_page = old_page
        @time = time
      end

      def url
        "#{@index_url}?#{CGI.escape(@new_page.page)}"
      end

      def self.load(filename, delete=false)
        r = nil
        open(filename) do |f|
          r = Marshal.load(f)
        end
        File.delete(filename) if r.is_a?(self) and delete
        r.is_a?(self) ? r : nil
      end

      def self.load_from_cache(id, delete=false)
        return nil unless id=~/\A[HSD]\d+\z/
        load("#{cache_path}/#{id}", delete)
      end

      def token
        tl = TokenList.new
        tl.add_text(diff_text)
        tl.add_host(@new_page.remote_addr, "A") if @new_page.remote_addr
        tl.add_message(@new_page.page) unless @old_page.page
        tl.add_message(@new_page.title) unless @new_page.title==@old_page.title
        tl.add_text(diff_keyword.join("\n"))
        tl
      end

      def ham?
        case BayesFilter.db.estimate(token)
        when 0..BayesFilter.threshold_ham
          true
        when BayesFilter.threshold..1.0
          false
        else
          nil
        end
      end

      def file_name
        @time.strftime("%Y%m%d%H%M%S") << format("%06d", @time.usec)
      end

      def self.cache_path
        BayesFilter.cache_path
      end
      def cache_path; self.class.cache_path; end

      def self.corpus_path
        r = "#{cache_path}/corpus"
        FileUtils.mkpath(r)
        r
      end
      def corpus_path; self.class.corpus_path; end

      CACHE_HEADER = {true=>"H", false=>"S", nil=>"D"}
      def cache_file_name
        "#{cache_path}/#{CACHE_HEADER[ham?]}#{file_name}"
      end

      def corpus_file_name(ham)
        "#{corpus_path}/#{ham ? "H" : "S"}#{file_name}"
      end
      def corpus_file_name_ham; corpus_file_name(true); end
      def corpus_file_name_spam; corpus_file_name(false); end

      FILE_CREATE_RETRY = 10
      def open(method)
        f = nil
        last_error = nil
        FILE_CREATE_RETRY.times do
          begin
            f = Kernel.open(send(method), File::WRONLY|File::CREAT|File::EXCL)
            break if f
          rescue Errno::EEXIST => last_error
            @time = Time.local(@time.year, @time.mon, @time.day, @time.hour, @time.min, @time.sec, @time.usec+1)
          end
        end
        unless f
          @time = Time.local(@time.year, @time.mon, @time.day, @time.hour, @time.min, @time.sec, @time.usec-FILE_CREATE_RETRY)
          raise last_error
        end
        yield(f)
      ensure
        f.close if f
      end

      def cache_save
        open(:cache_file_name) do |f|
          Marshal.dump(self, f)
        end
      end

      def corpus_save(ham)
        open(ham ? :corpus_file_name_ham : :corpus_file_name_spam) do |f|
          Marshal.dump(self, f)
        end
      end

      def diff_text
        ((@new_page.text||"").split("\n")-(@old_page.text||"").split("\n")).join("\n")
      end

      def diff_keyword
        (@new_page.keyword||[])-(@old_page.keyword||[])
      end

      def get_unified_diff
        unified_diff(@old_page.text||"", @new_page.text||"")
      end
    end
  end

  REPORT_PREFIX = {true=>"HAM", false=>"SPAM", nil=>"DOUBT"}
  add_filter do |new_page, old_page, posted_by_user|
    next unless @conf['bayes_filter.use']
    BayesFilter.init(@conf).filter(new_page, old_page, posted_by_user)
  end
end
