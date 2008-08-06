# $Id: test_repos_hg.rb,v 1.1 2008-08-06 10:48:25 hiraku Exp $
# Copyright (C) 2008, KURODA Hiraku <hiraku{@}hinet.mydns.jp>
# This code is modified from "test/test_repos_git.rb" by Kouhei Sutou
# You can distribute this under GPL.

require 'test/unit'
require 'fileutils'
require 'hiki/repos/hg'
require 'hiki/util'

class Repos_Hg_Tests < Test::Unit::TestCase
  def setup
    @tmp_dir = File.join(File.dirname(__FILE__), "tmp")
    @root = "#{@tmp_dir}/root"
    @wiki = 'wikiwiki'
    @data_dir = "#{@tmp_dir}/data"
    @text_dir = "#{@data_dir}/text"
    @repos = Hiki::ReposHg.new(@root, @data_dir)

    FileUtils.mkdir_p(@text_dir)
    Dir.chdir(@text_dir) do
      hg("init")
    end
  end

  def teardown
    FileUtils.rm_rf(@tmp_dir)
  end

  def test_commit
    write("FooBar", 'foobar')
    @repos.commit('FooBar')
    assert_equal('foobar', read('FooBar'))
    file = nil

    write("FooBar", 'foobar new')
    @repos.commit('FooBar')
    assert_equal('foobar new', read('FooBar'))

    Dir.chdir(@text_dir) do
      assert_equal("foobar new", hg("cat", "FooBar"))
    end
  end

  def test_get_revision
    rev1 = rev2 = rev3 = nil
    write("HogeHoge", 'hogehoge1')
    Dir.chdir(@text_dir) {hg("add", "HogeHoge")}
    Dir.chdir(@text_dir) {hg("commit", "-m", "First", "HogeHoge")}
    write("HogeHoge", 'hogehoge2')
    Dir.chdir(@text_dir) {hg("commit", "-m", "Second", "HogeHoge")}
    write("HogeHoge", 'hogehoge3')
    Dir.chdir(@text_dir) {hg("commit", "-m", "Third", "HogeHoge")}

    assert_equal('hogehoge1', @repos.get_revision('HogeHoge', 1))
    assert_equal('hogehoge2', @repos.get_revision('HogeHoge', 2))
    assert_equal('hogehoge3', @repos.get_revision('HogeHoge', 3))
  end

  def test_revisions
    rev1 = rev2 = rev3 = nil
    write("HogeHoge", 'hogehoge1')
    Dir.chdir(@text_dir) {hg("add", "HogeHoge")}
    Dir.chdir(@text_dir) {hg("commit", "-m", "First", "HogeHoge")}
    write("HogeHoge", 'hogehoge2')
    Dir.chdir(@text_dir) {hg("commit", "-m", "Second", "HogeHoge")}
    write("HogeHoge", 'hogehoge3')
    Dir.chdir(@text_dir) {hg("commit", "-m", "Third", "HogeHoge")}

    modified = Time.now.localtime.strftime('%Y/%m/%d %H:%M:%S')
    expected = [
                [3, modified, '', 'Third'],
                [2, modified, '', 'Second'],
                [1, modified, '', 'First'],
               ]

    assert_equal(expected, @repos.revisions('HogeHoge'))
  end

  private
  def hg(*args)
    args = args.collect{|arg| arg.dump}.join(' ')
    result = `hg #{args}`.chomp
    raise result unless $?.success?
    result
  end

  def file_name(page)
    "#{@data_dir}/text/#{page}"
  end

  def write(page, content)
    File.open(file_name(page), "wb") do |f|
      f.print(content)
    end
  end

  def read(page)
    File.open(file_name(page), "rb") do |f|
      f.read
    end
  end
end
