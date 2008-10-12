# Copyright (C) 2008, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2. 

require "tmpdir"
require "fileutils"
require "hiki/command"
$: << "hiki"

module SetupBayesFilter

  def self.included(ex)
    ex.before do
      @tmpdir = "#{Dir.tmpdir}/hiki_filter_spec_#{$$}"
      FileUtils.mkdir(@tmpdir)

      @index_url = "http://www.example.org/hiki/"
      @opt = {
      }
      @conf = stub("Hiki::Config",
        :data_path=>@tmpdir,
        :cache_path=>"#{@tmpdir}/cache",
        :bayes_threshold=>nil,
        :site_name=>"SiteName",
        :index_url=>@index_url,
        :null_object=>false)
      @conf.should_receive("[]".intern).any_number_of_times{|k| @opt[k]}
      @bf = Hiki::Filter::BayesFilter.init(@conf)
    end

    ex.after do
      FileUtils.remove_entry_secure(@tmpdir)
    end
  end
end

class << Object.new
  class Dummy
    include Hiki::Filter::BayesFilter
    def conf
      @@hiki_conf
    end
  end

  describe Hiki::Filter::BayesFilter do
    include SetupBayesFilter

    it "@@hiki_conf.index_url should return correct URL" do
      Dummy.new.conf.index_url.should == @index_url
    end
  end
end

describe Hiki::Filter::BayesFilter, "with default settings" do
  include SetupBayesFilter

  it "is module" do
    @bf.should be_kind_of(Module)
  end

  it "threshold" do
    @bf.threshold.should == 0.9
  end

  it "threshold_ham" do
    @bf.threshold_ham.should == 0.1
  end

  it "db" do
    @bf.db.should be_kind_of(Bayes::PlainBayes)
    @bf.db.db_name.should == "#{@tmpdir}/bayes.db"
    File.should_not be_exist(@bf.db.db_name)
    lambda{@bf.db.save}.should_not raise_error
    File.should be_exist(@bf.db.db_name)
  end

  it "new db" do
    @bf.db.ham << "ham"
    @bf.db.ham.should be_include("ham")
    @bf.new_db
    @bf.db.ham.should_not be_include("ham")
  end

  it "cache_path" do
    path = "#{@tmpdir}/cache/bayes"
    File.should_not be_exist(path)
    @bf.cache_path.should == path
    File.should be_exist(path)
  end

  it ".filter should not call Hiki::Filter.plugin.sendmail" do
    new_page = Hiki::Filter::PageData.new(
      "Page",
      "text",
      "title")
    old_page = Hiki::Filter::PageData.new("Page")
    plugin = stub("plugin")
    Hiki::Filter.should_not_receive(:plugin)
    lambda{@bf.filter(new_page, old_page, true)}.should_not raise_error
    lambda{@bf.filter(new_page, old_page, false)}.should_not raise_error
  end
end

describe Hiki::Filter::BayesFilter, "with settings" do
  include SetupBayesFilter

  before do
    @opt["bayes_filter.type"] = "Paul Graham"
    @opt["bayes_filter.report"] = "1"
    @opt["bayes_filter.threshold"] = "0.9"
    @conf.should_receive("[]".intern).any_number_of_times{|k| @opt[k]}
    @bf = Hiki::Filter::BayesFilter.init(@conf)
  end

  it "is module" do
    @bf.should be_kind_of(Module)
  end

  it "threshold" do
    @bf.threshold.should == 0.90
  end

  it "db" do
    @bf.db.should be_kind_of(Bayes::PaulGraham)
  end

  it "page_is_ham?" do
    db = mock("database")
    Hiki::Filter::BayesFilter.stub!(:db).and_return(db)

    pd = Hiki::Filter::PageData
    bfpd = Hiki::Filter::BayesFilter::PageData

    db.stub!(:estimate).and_return(0.0)
    bfpd.new(pd.new("Page", "text")).ham?.should be_true

    db.stub!(:estimate).and_return(1.0)
    bfpd.new(pd.new("Page", "spam")).ham?.should be_false

    db.stub!(:estimate).and_return(0.5)
    bfpd.new(pd.new("Page", "ham spam")).ham?.should == nil

    db.stub!(:estimate).and_return(nil)
    bfpd.new(pd.new("Page", "ham spam")).ham?.should == nil
  end

  it ".filter should call Hiki::Filter.plugin.sendmail" do
    new_page = Hiki::Filter::PageData.new(
      "Page",
      "text",
      "title")
    old_page = Hiki::Filter::PageData.new("Page")
    plugin = stub("plugin")
    plugin.should_receive(:sendmail)
    Hiki::Filter.should_receive(:plugin).and_return(plugin)
    lambda{@bf.filter(new_page, old_page, false)}.should_not raise_error
  end

  it ".filter should not call Hiki::Filter.plugin.sendmail when posted by registered user" do
    new_page = Hiki::Filter::PageData.new(
      "Page",
      "text",
      "title")
    old_page = Hiki::Filter::PageData.new("Page")
    Hiki::Filter.should_not_receive(:plugin)
    lambda{@bf.filter(new_page, old_page, true)}.should_not raise_error
  end
end

describe Hiki::Filter::BayesFilter::PageData do
  include SetupBayesFilter

  it "url" do
    pd = Hiki::Filter::BayesFilter::PageData.new(Hiki::Filter::PageData.new("Wiki Name", "text"))
    pd.url.should == "#{@index_url}?Wiki+Name"
  end

  it "ham?" do
    pd = Hiki::Filter::PageData
    bfpd = Hiki::Filter::BayesFilter::PageData
    bfpd.new(pd.new("Page", "text")).ham?.should be_nil

    @bf.db.ham << ["ham"]
    bfpd.new(pd.new("Page", "ham")).ham?.should be_true

    @bf.db.spam << ["spam"]
    bfpd.new(pd.new("Page", "spam")).ham?.should be_false
    bfpd.new(pd.new("Page", "ham spam")).ham?.should be_nil
  end

  it "token" do
    pd = Hiki::Filter::PageData
    bfpd = Hiki::Filter::BayesFilter::PageData
    o = pd.new("Page", "text", "Title", "keyword", "127.0.0.1")
    tl = Hiki::Filter::BayesFilter::TokenList.new
    tl << "Page" << "text" << "Title" << "keyword"
    tl.add_host("127.0.0.1", "A")
    bfpd.new(o).token.sort.should == tl.sort

    tl.clear.add_host("127.0.0.1", "A")
    bfpd.new(o.dup, o).token.sort.should == tl.sort

    tl.clear << "newtext" << "New" << "newword"
    tl.add_host("127.0.0.2", "A")
    bfpd.new(pd.new("Page", "text\nnewtext", "New", "newword\nkeyword", "127.0.0.2"), o).token.sort.should == tl.sort
  end

  it "diff_text" do
    pd = Hiki::Filter::PageData
    Hiki::Filter::BayesFilter::PageData.new(pd.new("", "old1\nnew1\nold2\nnew2"), pd.new("", "old1\nold2")).diff_text.should == "new1\nnew2"
  end

  it "diff_keyword" do
    pd = Hiki::Filter::PageData
    Hiki::Filter::BayesFilter::PageData.new(pd.new(nil, nil, nil, "old1\nnew1\nold2\nnew2"), pd.new(nil, nil, nil, "old1\nold2")).diff_keyword.sort.should == ["new1", "new2"].sort
  end

  it "get_unified_diff" do
    pd = Hiki::Filter::PageData
    Hiki::Filter::BayesFilter::PageData.new(pd.new("", "old1\nnew1\nold2\nnew2\n"), pd.new("", "old1\nold2\n")).get_unified_diff.should == "@@ -1,2 +1,4 @@\n old1\n+new1\n old2\n+new2\n"
  end
end

describe Hiki::Filter::BayesFilter::PageData, "save and load" do
  include SetupBayesFilter

  before do
    @time = Time.local(2001,2,3,4,5,6,7)
    @time2 = Time.local(2001,2,3,4,5,6,8)
    @time_str = @time.strftime("%Y%m%d%H%M%S") << format("%06d", @time.usec)
    @time2_str = @time2.strftime("%Y%m%d%H%M%S") << format("%06d", @time2.usec)
    pd = Hiki::Filter::PageData
    bp = Hiki::Filter::BayesFilter::PageData
    @pd = bp.new(pd.new("WikiName", "text", "Title of page", "key\nword", "127.0.0.1"), pd.new, @time)
  end

  it "time_str" do
    @time_str.should == "20010203040506000007"
  end

  it "file_name" do
    @pd.file_name.should == @time_str
  end

  it "PageData#cache_path" do
    path = "#{@tmpdir}/cache/bayes"
    File.should_not be_exist(path)
    @pd.cache_path.should == path
    File.should be_exist(path)
  end

  it "PageData.cache_path" do
    path = "#{@tmpdir}/cache/bayes"
    File.should_not be_exist(path)
    Hiki::Filter::BayesFilter::PageData.cache_path.should == path
    File.should be_exist(path)
  end

  it "PageData#corpus_path" do
    path = "#{@tmpdir}/cache/bayes/corpus"
    File.should_not be_exist(path)
    @pd.corpus_path.should == path
    File.should be_exist(path)
  end

  it "PageData.corpus_path" do
    path = "#{@tmpdir}/cache/bayes/corpus"
    File.should_not be_exist(path)
    Hiki::Filter::BayesFilter::PageData.corpus_path.should == path
    File.should be_exist(path)
  end

  it "cache_file_name if DOUBT" do
    @pd.cache_file_name.should == "#{@tmpdir}/cache/bayes/D#{@time_str}"
  end

  it "cache_file_name if HAM" do
    @bf.db.ham << ["text"]
    @pd.cache_file_name.should == "#{@tmpdir}/cache/bayes/H#{@time_str}"
  end

  it "cache_file_name if SPAM" do
    @bf.db.spam << ["WikiName", "New", "Title"]
    @pd.cache_file_name.should == "#{@tmpdir}/cache/bayes/S#{@time_str}"
  end

  it "save and load" do
    File.should_not be_exist(@pd.cache_file_name)
    @pd.cache_save
    File.should be_exist(@pd.cache_file_name)
    pd2 = Hiki::Filter::BayesFilter::PageData.load(@pd.cache_file_name)
    pd2.should be_kind_of(Hiki::Filter::BayesFilter::PageData)
    [:page, :text, :title, :keyword, :remote_addr].each do |m|
      pd2.old_page.send(m).should == @pd.old_page.send(m)
      pd2.new_page.send(m).should == @pd.new_page.send(m)
    end
    pd2.time.should == @pd.time
  end

  it "load and delete" do
    @pd.cache_save
    File.should be_exist(@pd.cache_file_name)
    Hiki::Filter::BayesFilter::PageData.load(@pd.cache_file_name)
    File.should be_exist(@pd.cache_file_name)
    Hiki::Filter::BayesFilter::PageData.load(@pd.cache_file_name, true)
    File.should_not be_exist(@pd.cache_file_name)

    path = "#{@tmpdir}/dummy"
    open(path, "w") do |f|
      Marshal.dump([], f)
    end
    File.should be_exist(path)
    Hiki::Filter::BayesFilter::PageData.load(path)
    File.should be_exist(path)
    Hiki::Filter::BayesFilter::PageData.load(path, true)
    File.should be_exist(path)
  end

  it "load invalid data and return nil" do
    file = "#{@tmpdir}/dummy"
    open(file, "w") do |f|
      Marshal.dump([], f)
    end
    Hiki::Filter::BayesFilter::PageData.load(file).should be_nil
  end

  it "load cache" do
    @pd.cache_save
    pd = Hiki::Filter::BayesFilter::PageData.load_from_cache(@pd.cache_file_name[/.\d+$/])
    pd.cache_file_name.should == @pd.cache_file_name
    Hiki::Filter::BayesFilter::PageData.load_from_cache(@pd.cache_file_name[/.\d+$/], true)
    File.should_not be_exist(@pd.cache_file_name)
  end

  it "save different data at same time" do
    fn = @pd.cache_file_name
    @pd.cache_save
    @pd.cache_file_name.should == fn
    @pd.time.should == @time

    @pd.cache_save
    @pd.time.should_not == @time
    @pd.time.should == @time2
    @pd.file_name.should == @time2_str
    @pd.cache_file_name.should == "#{@tmpdir}/cache/bayes/D#{@time2_str}"
  end

  it "saving at same time over 10 times raise error" do
    time = @time.dup
    10.times do
      lambda{@pd.cache_save}.should_not raise_error
    end
    @time.should == time
    pd2 = Hiki::Filter::BayesFilter::PageData.new(Hiki::Filter::PageData.new("Page", "text", "Title"), Hiki::Filter::PageData.new, @time)
    lambda{pd2.cache_save}.should raise_error(Errno::EEXIST)
    pd2.time.should == time
  end

  it "corpus_save" do
    ham = "#{@tmpdir}/cache/bayes/corpus/H#{@time_str}"
    spam = "#{@tmpdir}/cache/bayes/corpus/S#{@time_str}"
    File.should_not be_exist(ham)
    File.should_not be_exist(spam)

    @pd.corpus_save(true)
    File.should be_exist(ham)
    @pd.corpus_save(false)
    File.should be_exist(spam)
  end
end
