# coding: utf-8

require "test_helper"
require "hiki/config"
require "hiki/storage/flatfile"
require "digest/md5"

class HikiDB_flatfile_Unit_Tests < Test::Unit::TestCase
  include TestHelper
  include FileUtils

  def setup
    @wiki_data_path = fixtures_dir + "plain_data"
    cp_r(fixtures_dir + "plain_data.prepare", @wiki_data_path)
    config_path = (fixtures_dir + "hikiconf_default.rb").expand_path
    @conf = Hiki::Config.new(config_path)
    @db = Hiki::Storage::Flatfile.new(@conf)
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

  def test_pages
    expected = %w[FrontPage InterWikiName SideMenu TextFormattingRules].sort
    assert_equal(expected, @db.pages.sort)
  end

  def test_load_backup
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
    @db.store("FrontPage", "test", Digest::MD5.hexdigest(expected))
    assert_equal(expected, @db.load_backup("FrontPage"))
  end

  def test_load_backup_no_such_page
    assert_nil(@db.load_backup("NoSuchPage"))
  end

  def test_backup_exist
    text = @db.load("FrontPage")
    @db.store("FrontPage", "test", Digest::MD5.hexdigest(text))
    @db.backup_exist?("FrontPage")
  end

  def test_backup_exist_no_such_page
    @db.backup_exist?("NoSuchPage")
  end

  def test_unlink
    assert_false(@db.backup_exist?("FrontPage"))
    @db.unlink("FrontPage")
    assert_false(@db.exist?("FrontPage"))
    assert_true(@db.backup_exist?("FrontPage"))
  end

  def test_unlink_no_such_page
    assert_nothing_raised { @db.unlink("NoSuchPage") }
  end

  def test_rename
    expected = @db.load("FrontPage")
    @db.rename("FrontPage", "Hoge")
    assert_equal(expected, @db.load("Hoge"))
  end

  def test_rename_new_page_already_exist
    assert_raise(ArgumentError) do
      @db.rename("FrontPage", "InterWikiName")
    end
  end
end
