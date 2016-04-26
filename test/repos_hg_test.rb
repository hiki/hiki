# -*- coding: utf-8 -*-
# Copyright (C) 2008, KURODA Hiraku <hiraku{@}hinet.mydns.jp>
# This code is modified from "test/test_repos_git.rb" by Kouhei Sutou
# You can distribute this under GPL.

require "test_helper"
require "hiki/repository/hg"
require "hiki/util"

class Repos_Hg_Tests < Test::Unit::TestCase
  include Hiki::Util
  include TestHelper

  def setup
    @tmp_dir = File.join(File.dirname(__FILE__), "tmp")
    @root = "#{@tmp_dir}/root"
    @wiki = "wikiwiki"
    @data_dir = "#{@tmp_dir}/data"
    @text_dir = "#{@data_dir}/text"
    @repos = Hiki::Repository::Hg.new(@root, @data_dir)

    FileUtils.mkdir_p(@text_dir)
    check_command("hg")
    Dir.chdir(@text_dir) do
      hg("init")
      create_hgrc
    end
  end

  def teardown
    FileUtils.rm_rf(@tmp_dir)
  end

  def test_commit
    write("FooBar", "foobar")
    @repos.commit("FooBar")
    assert_equal("foobar", read("FooBar"))

    write("FooBar", "foobar new")
    @repos.commit("FooBar")
    assert_equal("foobar new", read("FooBar"))

    Dir.chdir(@text_dir) do
      assert_equal("foobar new", hg("cat", "FooBar"))
    end
  end

  def test_commit_with_content
    @repos.commit_with_content("FooBar", "foobar")
    assert_equal("foobar", read("FooBar"))
    @repos.commit_with_content("FooBar", "foobar new")
    assert_equal("foobar new", read("FooBar"))
  end

  def test_get_revision
    write("HogeHoge", "hogehoge1")
    Dir.chdir(@text_dir) {hg("add", "HogeHoge")}
    Dir.chdir(@text_dir) {hg("commit", "-m", "First", "HogeHoge")}
    write("HogeHoge", "hogehoge2")
    Dir.chdir(@text_dir) {hg("commit", "-m", "Second", "HogeHoge")}
    write("HogeHoge", "hogehoge3")
    Dir.chdir(@text_dir) {hg("commit", "-m", "Third", "HogeHoge")}

    assert_equal("hogehoge1", @repos.get_revision("HogeHoge", 1))
    assert_equal("hogehoge2", @repos.get_revision("HogeHoge", 2))
    assert_equal("hogehoge3", @repos.get_revision("HogeHoge", 3))
  end

  def test_revisions
    write("HogeHoge", "hogehoge1")
    Dir.chdir(@text_dir) {hg("add", "HogeHoge")}
    Dir.chdir(@text_dir) {hg("commit", "-m", "First", "HogeHoge")}
    modified1 = Time.now.localtime.strftime("%Y/%m/%d %H:%M:%S")
    write("HogeHoge", "hogehoge2")
    Dir.chdir(@text_dir) {hg("commit", "-m", "Second", "HogeHoge")}
    modified2 = Time.now.localtime.strftime("%Y/%m/%d %H:%M:%S")
    write("HogeHoge", "hogehoge3")
    Dir.chdir(@text_dir) {hg("commit", "-m", "Third", "HogeHoge")}
    modified3 = Time.now.localtime.strftime("%Y/%m/%d %H:%M:%S")

    expected = [
                [3, modified3, "", "Third"],
                [2, modified2, "", "Second"],
                [1, modified1, "", "First"],
               ].transpose
    actual = @repos.revisions("HogeHoge").transpose

    assert_equal(expected[0], actual[0])
    # disable to fragile test
    # assert_equal(expected[1], actual[1])
    assert_equal(expected[2], actual[2])
    assert_equal(expected[3], actual[3])
  end

  def test_rename
    write("HogeHoge", "hogehoge1\n")
    @repos.commit("HogeHoge")
    @repos.rename("HogeHoge", "FooBar")
    assert_equal("hogehoge1\n", read("FooBar"))
  end

  def test_rename_multibyte
    write(escape("ほげほげ"), "hogehoge1\n")
    @repos.commit("ほげほげ")
    @repos.rename("ほげほげ", "ふーばー")
    assert_equal("hogehoge1\n", read(escape("ふーばー")))
  end

  def test_rename_new_page_already_exist
    write("HogeHoge", "hogehoge1\n")
    @repos.commit("HogeHoge")
    write("FooBar", "foobar\n")
    @repos.commit("FooBar")
    assert_raise(ArgumentError) do
      @repos.rename("HogeHoge", "FooBar")
    end
  end

  def test_pages
    write(escape("ほげほげ"), "hogehoge1\n")
    @repos.commit("ほげほげ")
    write("FooBar", "foobar\n")
    @repos.commit("FooBar")

    expected = ["ほげほげ", "FooBar"]
    expected = expected.map{|v| v.force_encoding("binary") }
    assert_equal(expected.sort, @repos.pages.sort)
  end

  def test_pages_with_block
    write(escape("ほげほげ"), "hogehoge1\n")
    @repos.commit("ほげほげ")
    write("FooBar", "foobar\n")
    @repos.commit("FooBar")

    actuals = []
    @repos.pages.each do |page|
      actuals << page
    end

    expected = ["ほげほげ", "FooBar"]
    expected = expected.map{|v| v.force_encoding("binary") }

    assert_equal(expected.sort, actuals.sort)
  end

  private
  def hg(*args)
    args = args.collect{|arg| arg.dump}.join(" ")
    result = `hg #{args}`.chomp
    raise result unless $?.success?
    result
  end
end
