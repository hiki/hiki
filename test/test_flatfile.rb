# coding: utf-8

require 'test/unit'
require 'hiki/config'
require 'hiki/db/flatfile'
require 'fileutils'
require 'test_helper'

class HikiDB_flatfile_Unit_Tests < Test::Unit::TestCase
  include TestHelper
  include FileUtils

  def setup
    @wiki_data_path = fixtures_dir + "plain_data"
    cp_r(fixtures_dir + "plain_data.prepare", @wiki_data_path)
    config_path = (fixtures_dir + "hikiconf_default.rb").expand_path
    @conf = Hiki::Config.new(config_path)
    @db = Hiki::HikiDB_flatfile.new(@conf)
  end

  def teardown
    rm_rf(@wiki_data_path)
  end

  def test_close_db
    assert(@db.close_db)
  end

  def test_load
    expected = <<STR
!ようこそ

これはWikiエンジン[[Hiki|http://hikiwiki.org/ja/]]のFrontPageです。
このページが見えているならインストールはうまくいっています。多分(^^;

!使い始める前に（重要）

ページ上部にある[管理]アンカをクリックし管理者用パスワードを設定してください。
各ページの凍結（管理者以外の更新を抑止する）とその解除は管理者のみ行うことができます。

!Hikiの書式について

Hikiの書式はオリジナルWikiに似てますので、オリジナルの書式を知っている方は
スムーズにコンテンツを記述することができるでしょう。ただし、一部、独自に拡張している
書式もありますので、詳細についてはTextFormattingRulesを参照してください。
STR
    assert_equal(expected, @db.load("FrontPage"))
  end

  def test_load_no_such_page
    assert_nil(@db.load("NoSuchPage"))
  end

  def test_exist
    assert_true(@db.exist?("FrontPage"))
  end

  def test_exist_no_such_page
    assert_false(@db.exist?("NoSuchPage"))
  end
end
