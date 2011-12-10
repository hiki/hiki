# Copyright (C) 2008, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2. 

module Hiki
  class Plugin
  end
end
require "tmpdir"
require "hiki/filter"
require "plugin/ja/50bayes_filter"
require "plugin/50bayes_filter"

class << Object.new
  BayesFilter = Hiki::Filter::BayesFilter

  module Common
    def self.included(ex)
      ex.before do
        @tmpdir = "#{Dir.tmpdir}/hiki_filter_spec_#{$$}"
        FileUtils.mkdir(@tmpdir)

        @base_url = "http://www.example.org/hiki.cgi"
        @opt = {}
        @conf = stub("conf",
          :data_path=>@tmpdir,
          :cache_path=>"#{@tmpdir}/cache",
          :bayes_threshold=>nil,
          :filter_type=>nil,
          :cgi_name=>@base_url,
          :index_url=>@base_url,
          :null_object=>false)
        @conf.should_receive("[]".intern).any_number_of_times{|k| @opt[k]}
        @conf.should_receive("[]=".intern).any_number_of_times{|k, v| @opt[k]=v}
        BayesFilter.init(@conf)
      end

      ex.after do
        FileUtils.remove_entry_secure(@tmpdir)
      end

      ex.before do
        @params = Hash.new{|h, k| h[k]=[]}
        @cgi = stub("cgi",
          :params=>@params,
          :request_method=>"POST",
          :null_object=>false)
        @pages = []
        @db = stub("db",
          :pages=>@pages,
          :null_object=>false)
        @c = BayesFilterConfig.new(@cgi, @conf, "saveconf", @db)
      end
    end
  end

  describe BayesFilterConfig::Res do
    it "support Japanese and English" do
      ["ja", "en"].each do |la|
        src = IO.read("plugin/#{la}/50bayes_filter.rb")
        rb = "module #{la.upcase}\n#{src}\nend"
        eval(rb, binding)
      end

      [EN].each do |m|
        JA::BayesFilterConfig::Res.methods.sort.should == m::BayesFilterConfig::Res.methods.sort
      end
    end
  end

  describe BayesFilterConfig, "default" do
    include Common

    it "html" do
      lambda{@c.html}.should_not raise_error
    end

    it "conf_url" do
      @c.conf_url.should == "#{@base_url}?c=admin;conf=bayes_filter"
      @c.conf_url("hoge").should == "#{@base_url}?c=admin;conf=bayes_filter;bfmode=hoge"
    end

    it "save_mode?" do
      @c.save_mode?.should be_true
      @cgi.stub!(:request_method).and_return("GET")
      @c.save_mode?.should be_false
      @cgi.stub!(:request_method).and_return("POST")
      @c.save_mode?.should be_true
      @c.instance_variable_set("@confmode", "conf")
      @c.save_mode?.should be_false
    end
  end

  describe BayesFilterConfig, "submitted page list" do
    include Common

    before do
      @params["bfmode"] << BayesFilterConfig::Mode::SUBMITTED_PAGES

      BayesFilter.db.ham << ["ham"]
      BayesFilter.db.spam << ["spam"]
      bp = Hiki::Filter::BayesFilter::PageData
      pd = Hiki::Filter::PageData
      @ham = bp.new(pd.new("ham", "ham", "ham", "ham", "127.0.0.1"))
      @ham.cache_save
      @spam = bp.new(pd.new("spam", "spam", "spam", "spam", "127.0.0.1"))
      @spam.cache_save
      @doubt = bp.new(pd.new("ham spam", "ham spam", "ham spam", "ham spam", "127.0.0.1"))
      @doubt.cache_save
    end

    it "setting test" do
      @ham.ham?.should be_true
      @spam.ham?.should be_false
      @doubt.ham?.should be_nil
    end

    it "html" do
      lambda{@c.html}.call #should_not raise_error
    end

    it "submitted_pages" do
      l = @c.submitted_pages
      l.ham.values.map{|i| i.cache_file_name}.should == [@ham.cache_file_name]
      l.ham.each_pair{|k, d| k.should == d.cache_file_name[/H\d+$/]}
      l.spam.values.map{|i| i.cache_file_name}.should == [@spam.cache_file_name]
      l.spam.each_pair{|k, d| k.should == d.cache_file_name[/S\d+$/]}
      l.doubt.values.map{|i| i.cache_file_name}.should == [@doubt.cache_file_name]
      l.doubt.each_pair{|k, d| k.should == d.cache_file_name[/D\d+$/]}
    end
  end

  describe BayesFilterConfig, "process page data" do
    include Common

    before do
      @params["bfmode"] << BayesFilterConfig::Mode::PROCESS_PAGE_DATA

      BayesFilter.db.ham << ["ham"]
      BayesFilter.db.spam << ["spam"]
      pd = Hiki::Filter::PageData
      bp = Hiki::Filter::BayesFilter::PageData
      @ham = bp.new(pd.new("ham", "ham", "ham", "ham", "127.0.0.1"))
      @ham.cache_save
      @ham.ham?.should be_true
      @spam = bp.new(pd.new("spam", "spam", "spam", "spam", "127.0.0.1"))
      @spam.cache_save
      @spam.ham?.should be_false
      @doubt = bp.new(pd.new("ham spam", "ham spam", "ham spam", "ham spam", "127.0.0.1"))
      @doubt.cache_save
      @doubt.ham?.should be_nil
    end

    it "html" do
      @c.should_receive(:process_page_data){@c.proxied_by_rspec__process_page_data}
      lambda{@c.html}.should_not raise_error
    end

    it "process data" do
      ham_id = "H#{@ham.file_name}"
      @params[ham_id] << "1"
      @params["register_#{ham_id}"] << "spam"
      @c.save_mode?.should be_true
      @c.process_page_data
      File.should_not be_exist(@ham.cache_file_name)
      File.should be_exist(@ham.corpus_file_name_spam)
      @ham.ham?.should be_false
    end
  end

  describe BayesFilterConfig, "with Bayes::PaulGraham" do
    include Common

    before do
      @token = Bayes::TokenList.new
      @token << "w"
      @filter_db = Bayes::PaulGraham.new
      @filter_db.spam << @token
      @filter_db.ham << @token
      BayesFilter.stub!(:db).and_return(@filter_db)
    end

    it "should occur infinity-loop at #add_ham" do
      lambda{@c.add_ham(@token)}.should_not raise_error
    end

    it "should occur infinity-loop at #add_spam" do
      lambda{@c.add_spam(@token)}.should_not raise_error
    end
  end

  describe BayesFilterConfig, "with Bayes::PaulGraham" do
    include Common

    before do
      @token = Bayes::TokenList.new
      @token << "w"
      @filter_db = Bayes::PaulGraham.new
      @filter_db.spam << @token
      @filter_db.ham << @token
      BayesFilter.stub!(:db).and_return(@filter_db)
    end

    it "should occur infinity-loop at #add_ham" do
      lambda{@c.add_ham(@token)}.should_not raise_error
    end

    it "should occur infinity-loop at #add_spam" do
      lambda{@c.add_spam(@token)}.should_not raise_error
    end
  end

  describe BayesFilterConfig, "ham/spam token list" do
    include Common

    it "html(ham)" do
      @params["bfmode"] << BayesFilterConfig::Mode::HAM_TOKENS
      @c.should_receive(:tokens_html){|token, title| @c.proxied_by_rspec__tokens_html(token, title)}
      lambda{@c.html}.should_not raise_error
    end

    it "html(spam)" do
      @params["bfmode"] << BayesFilterConfig::Mode::SPAM_TOKENS
      @c.should_receive(:tokens_html){|token, title| @c.proxied_by_rspec__tokens_html(token, title)}
      lambda{@c.html}.should_not raise_error
    end
  end

  describe BayesFilterConfig, "page diff" do
    include Common

    before do
      @params["bfmode"] << BayesFilterConfig::Mode::SUBMITTED_PAGE_DIFF
      @pd = Hiki::Filter::BayesFilter::PageData.new(
        Hiki::Filter::PageData.new("ham spam", "ham spam", "ham spam", "ham spam", "127.0.0.1"))
      @params["id"] << ("D"+@pd.file_name).taint
      @pd.cache_save
    end

    it "html" do
      @c.should_receive(:submitted_page_diff_html)
      lambda{@c.html}.should_not raise_error
    end

    it "submitted_page_diff_html" do
      $SAFE=1
      @c.should_receive(:word_diff)
      lambda{@c.submitted_page_diff_html}.should_not raise_error
    end
  end

  describe BayesFilterConfig, "tokens" do
    include Common
    before do
      @params["bfmode"] << BayesFilterConfig::Mode::PAGE_TOKEN
      @pd = Hiki::Filter::BayesFilter::PageData.new(
        Hiki::Filter::PageData.new("ham spam", "ham spam", "ham spam", "ham spam", "127.0.0.1"))
      @params["id"] << ("D"+@pd.file_name).taint
      @pd.cache_save
    end

    it "html" do
      @c.should_receive(:page_token_html)
      lambda{@c.html}.should_not raise_error
    end

    it "submitted_page_diff_html" do
      $SAFE=1
      lambda{@c.page_token_html}.should_not raise_error
    end
  end

  describe BayesFilterConfig, "rebuild DB" do
    include Common

    it "rebuild_db" do
      pd = Hiki::Filter::PageData
      Hiki::Filter::BayesFilter::PageData.new(pd.new("HamPage", "text")).corpus_save(true)
      Hiki::Filter::BayesFilter::PageData.new(pd.new("SpamPage", "text")).corpus_save(false)
      @pages << "TestPage"
      @db.should_receive(:load).and_return do |page|
        "Text" if page=="TestPage"
      end
      @db.should_receive(:get_attribute).any_number_of_times do |pg, attr|
        pg.should == "TestPage"
        case attr
        when :title
          "Title"
        when :keyword
          ["key", "word"]
        else
          puts attr
        end
      end

      Hiki::Filter::BayesFilter.should_receive(:new_db){Hiki::Filter::BayesFilter.proxied_by_rspec__new_db}
      lambda{$SAFE=1;@c.rebuild_db}.call #should_not raise_error
    end
  end
end
