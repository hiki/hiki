# Copyright (C) 2008, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2.

require 'spec_helper'

require "tmpdir"
require "fileutils"
require "hiki/command"

module SetupBayesFilter

  def self.included(ex)
    ex.before do
      @tmpdir = "#{Dir.tmpdir}/hiki_filter_spec_#{$$}"
      FileUtils.mkdir(@tmpdir)

      @index_url = "http://www.example.org/hiki/"
      @opt = {
      }
      @conf = double("Hiki::Config",
        data_path:@tmpdir,
        cache_path:"#{@tmpdir}/cache",
        bayes_threshold:nil,
        site_name:"SiteName",
        index_url:@index_url,
        null_object:false)
      allow(@conf).to receive("[]".intern){|k| @opt[k]}
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
      expect(Dummy.new.conf.index_url).to eq(@index_url)
    end
  end
end

describe Hiki::Filter::BayesFilter, "with default settings" do
  include SetupBayesFilter

  it "is module" do
    expect(@bf).to be_kind_of(Module)
  end

  it "threshold" do
    expect(@bf.threshold).to eq(0.9)
  end

  it "threshold_ham" do
    expect(@bf.threshold_ham).to eq(0.1)
  end

  it "db" do
    expect(@bf.db).to be_kind_of(Bayes::PlainBayes)
    expect(@bf.db.db_name).to eq("#{@tmpdir}/bayes.db")
    expect(File).not_to be_exist(@bf.db.db_name)
    expect{@bf.db.save}.not_to raise_error
    expect(File).to be_exist(@bf.db.db_name)
  end

  it "new db" do
    @bf.db.ham << "ham"
    expect(@bf.db.ham).to be_include("ham")
    @bf.new_db
    expect(@bf.db.ham).not_to be_include("ham")
  end

  it "cache_path" do
    path = "#{@tmpdir}/cache/bayes"
    expect(File).not_to be_exist(path)
    expect(@bf.cache_path).to eq(path)
    expect(File).to be_exist(path)
  end

  it ".filter should not call Hiki::Filter.plugin.sendmail" do
    new_page = Hiki::Filter::PageData.new(
      "Page",
      "text",
      "title")
    old_page = Hiki::Filter::PageData.new("Page")
    plugin = double("plugin")
    expect(Hiki::Filter).not_to receive(:plugin)
    expect{@bf.filter(new_page, old_page, true)}.not_to raise_error
    expect{@bf.filter(new_page, old_page, false)}.not_to raise_error
  end
end

describe Hiki::Filter::BayesFilter, "with settings" do
  include SetupBayesFilter

  before do
    @opt["bayes_filter.type"] = "Paul Graham"
    @opt["bayes_filter.report"] = "1"
    @opt["bayes_filter.threshold"] = "0.9"
    allow(@conf).to receive("[]".intern){|k| @opt[k]}
    @bf = Hiki::Filter::BayesFilter.init(@conf)
  end

  it "is module" do
    expect(@bf).to be_kind_of(Module)
  end

  it "threshold" do
    expect(@bf.threshold).to eq(0.90)
  end

  it "db" do
    expect(@bf.db).to be_kind_of(Bayes::PaulGraham)
  end

  it "page_is_ham?" do
    db = double("database")
    allow(Hiki::Filter::BayesFilter).to receive(:db).and_return(db)

    pd = Hiki::Filter::PageData
    bfpd = Hiki::Filter::BayesFilter::PageData

    allow(db).to receive(:estimate).and_return(0.0)
    expect(bfpd.new(pd.new("Page", "text")).ham?).to be true

    allow(db).to receive(:estimate).and_return(1.0)
    expect(bfpd.new(pd.new("Page", "spam")).ham?).to be false

    allow(db).to receive(:estimate).and_return(0.5)
    expect(bfpd.new(pd.new("Page", "ham spam")).ham?).to eq(nil)

    allow(db).to receive(:estimate).and_return(nil)
    expect(bfpd.new(pd.new("Page", "ham spam")).ham?).to eq(nil)
  end

  it ".filter should call Hiki::Filter.plugin.sendmail" do
    new_page = Hiki::Filter::PageData.new(
      "Page",
      "text",
      "title")
    old_page = Hiki::Filter::PageData.new("Page")
    plugin = double("plugin")
    expect(plugin).to receive(:sendmail)
    expect(Hiki::Filter).to receive(:plugin).and_return(plugin)
    expect{@bf.filter(new_page, old_page, false)}.not_to raise_error
  end

  it ".filter should not call Hiki::Filter.plugin.sendmail when posted by registered user" do
    new_page = Hiki::Filter::PageData.new(
      "Page",
      "text",
      "title")
    old_page = Hiki::Filter::PageData.new("Page")
    expect(Hiki::Filter).not_to receive(:plugin)
    expect{@bf.filter(new_page, old_page, true)}.not_to raise_error
  end
end

describe Hiki::Filter::BayesFilter::PageData do
  include SetupBayesFilter

  it "url" do
    pd = Hiki::Filter::BayesFilter::PageData.new(Hiki::Filter::PageData.new("Wiki Name", "text"))
    expect(pd.url).to eq("#{@index_url}?Wiki+Name")
  end

  it "ham?" do
    pd = Hiki::Filter::PageData
    bfpd = Hiki::Filter::BayesFilter::PageData
    expect(bfpd.new(pd.new("Page", "text")).ham?).to be_nil

    @bf.db.ham << ["ham"]
    expect(bfpd.new(pd.new("Page", "ham")).ham?).to be true

    @bf.db.spam << ["spam"]
    expect(bfpd.new(pd.new("Page", "spam")).ham?).to be false
    expect(bfpd.new(pd.new("Page", "ham spam")).ham?).to be_nil
  end

  it "token" do
    pd = Hiki::Filter::PageData
    bfpd = Hiki::Filter::BayesFilter::PageData
    o = pd.new("Page", "text", "Title", "keyword", "127.0.0.1")
    tl = Hiki::Filter::BayesFilter::TokenList.new
    tl << "Page" << "text" << "Title" << "keyword"
    tl.add_host("127.0.0.1", "A")
    expect(bfpd.new(o).token.sort).to eq(tl.sort)

    tl.clear.add_host("127.0.0.1", "A")
    expect(bfpd.new(o.dup, o).token.sort).to eq(tl.sort)

    tl.clear << "newtext" << "New" << "newword"
    tl.add_host("127.0.0.2", "A")
    expect(bfpd.new(pd.new("Page", "text\nnewtext", "New", "newword\nkeyword", "127.0.0.2"), o).token.sort).to eq(tl.sort)
  end

  it "diff_text" do
    pd = Hiki::Filter::PageData
    expect(Hiki::Filter::BayesFilter::PageData.new(pd.new("", "old1\nnew1\nold2\nnew2"), pd.new("", "old1\nold2")).diff_text).to eq("new1\nnew2")
  end

  it "diff_keyword" do
    pd = Hiki::Filter::PageData
    expect(Hiki::Filter::BayesFilter::PageData.new(pd.new(nil, nil, nil, "old1\nnew1\nold2\nnew2"), pd.new(nil, nil, nil, "old1\nold2")).diff_keyword.sort).to eq(["new1", "new2"].sort)
  end

  it "get_unified_diff" do
    pd = Hiki::Filter::PageData
    expect(Hiki::Filter::BayesFilter::PageData.new(pd.new("", "old1\nnew1\nold2\nnew2\n"), pd.new("", "old1\nold2\n")).get_unified_diff).to eq("@@ -1,2 +1,4 @@\n old1\n+new1\n old2\n+new2\n")
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
    expect(@time_str).to eq("20010203040506000007")
  end

  it "file_name" do
    expect(@pd.file_name).to eq(@time_str)
  end

  it "PageData#cache_path" do
    path = "#{@tmpdir}/cache/bayes"
    expect(File).not_to be_exist(path)
    expect(@pd.cache_path).to eq(path)
    expect(File).to be_exist(path)
  end

  it "PageData.cache_path" do
    path = "#{@tmpdir}/cache/bayes"
    expect(File).not_to be_exist(path)
    expect(Hiki::Filter::BayesFilter::PageData.cache_path).to eq(path)
    expect(File).to be_exist(path)
  end

  it "PageData#corpus_path" do
    path = "#{@tmpdir}/cache/bayes/corpus"
    expect(File).not_to be_exist(path)
    expect(@pd.corpus_path).to eq(path)
    expect(File).to be_exist(path)
  end

  it "PageData.corpus_path" do
    path = "#{@tmpdir}/cache/bayes/corpus"
    expect(File).not_to be_exist(path)
    expect(Hiki::Filter::BayesFilter::PageData.corpus_path).to eq(path)
    expect(File).to be_exist(path)
  end

  it "cache_file_name if DOUBT" do
    expect(@pd.cache_file_name).to eq("#{@tmpdir}/cache/bayes/D#{@time_str}")
  end

  it "cache_file_name if HAM" do
    @bf.db.ham << ["text"]
    expect(@pd.cache_file_name).to eq("#{@tmpdir}/cache/bayes/H#{@time_str}")
  end

  it "cache_file_name if SPAM" do
    @bf.db.spam << ["WikiName", "New", "Title"]
    expect(@pd.cache_file_name).to eq("#{@tmpdir}/cache/bayes/S#{@time_str}")
  end

  it "save and load" do
    expect(File).not_to be_exist(@pd.cache_file_name)
    @pd.cache_save
    expect(File).to be_exist(@pd.cache_file_name)
    pd2 = Hiki::Filter::BayesFilter::PageData.load(@pd.cache_file_name)
    expect(pd2).to be_kind_of(Hiki::Filter::BayesFilter::PageData)
    [:page, :text, :title, :keyword, :remote_addr].each do |m|
      expect(pd2.old_page.send(m)).to eq(@pd.old_page.send(m))
      expect(pd2.new_page.send(m)).to eq(@pd.new_page.send(m))
    end
    expect(pd2.time).to eq(@pd.time)
  end

  it "load and delete" do
    @pd.cache_save
    expect(File).to be_exist(@pd.cache_file_name)
    Hiki::Filter::BayesFilter::PageData.load(@pd.cache_file_name)
    expect(File).to be_exist(@pd.cache_file_name)
    Hiki::Filter::BayesFilter::PageData.load(@pd.cache_file_name, true)
    expect(File).not_to be_exist(@pd.cache_file_name)

    path = "#{@tmpdir}/dummy"
    open(path, "w") do |f|
      Marshal.dump([], f)
    end
    expect(File).to be_exist(path)
    Hiki::Filter::BayesFilter::PageData.load(path)
    expect(File).to be_exist(path)
    Hiki::Filter::BayesFilter::PageData.load(path, true)
    expect(File).to be_exist(path)
  end

  it "load invalid data and return nil" do
    file = "#{@tmpdir}/dummy"
    open(file, "w") do |f|
      Marshal.dump([], f)
    end
    expect(Hiki::Filter::BayesFilter::PageData.load(file)).to be_nil
  end

  it "load cache" do
    @pd.cache_save
    pd = Hiki::Filter::BayesFilter::PageData.load_from_cache(@pd.cache_file_name[/.\d+$/])
    expect(pd.cache_file_name).to eq(@pd.cache_file_name)
    Hiki::Filter::BayesFilter::PageData.load_from_cache(@pd.cache_file_name[/.\d+$/], true)
    expect(File).not_to be_exist(@pd.cache_file_name)
  end

  it "save different data at same time" do
    fn = @pd.cache_file_name
    @pd.cache_save
    expect(@pd.cache_file_name).to eq(fn)
    expect(@pd.time).to eq(@time)

    @pd.cache_save
    expect(@pd.time).not_to eq(@time)
    expect(@pd.time).to eq(@time2)
    expect(@pd.file_name).to eq(@time2_str)
    expect(@pd.cache_file_name).to eq("#{@tmpdir}/cache/bayes/D#{@time2_str}")
  end

  it "saving at same time over 10 times raise error" do
    time = @time.dup
    10.times do
      expect{@pd.cache_save}.not_to raise_error
    end
    expect(@time).to eq(time)
    pd2 = Hiki::Filter::BayesFilter::PageData.new(Hiki::Filter::PageData.new("Page", "text", "Title"), Hiki::Filter::PageData.new, @time)
    expect{pd2.cache_save}.to raise_error(Errno::EEXIST)
    expect(pd2.time).to eq(time)
  end

  it "corpus_save" do
    ham = "#{@tmpdir}/cache/bayes/corpus/H#{@time_str}"
    spam = "#{@tmpdir}/cache/bayes/corpus/S#{@time_str}"
    expect(File).not_to be_exist(ham)
    expect(File).not_to be_exist(spam)

    @pd.corpus_save(true)
    expect(File).to be_exist(ham)
    @pd.corpus_save(false)
    expect(File).to be_exist(spam)
  end
end
