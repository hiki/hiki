# -*- coding: utf-8 -*-
require "rack"
require "hiki/app"
require "test/unit/capybara"
require "fileutils"

module BasicScenario
  def test_title
    visit("/")
    within("h1") do
      assert_equal("FrontPage", text)
    end
  end

  def test_get_create
    visit("/?c=create")
    within("h1.header") do
      assert_equal("Test Wiki - Create", text)
    end
  end

  def test_create_new_page
    visit("/?c=create")
    fill_in("key", :with => "NewPage")
    click_button("New")
    fill_in("contents", :with => "Test Test")
    click_button("Save")
    click_link("Click here!")

    within("h1.header") do
      assert_equal("NewPage", text)
    end
    within(".body .section p") do
      assert_equal("Test Test", text)
    end
  end

  def test_edit_front_page
    visit("/")
    click_link("Edit")
    within("div.textarea textarea") do
      assert_equal(<<TEXT, text)
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
TEXT
    end
    fill_in("contents", :with => "FrontPage contents")
    click_button("Save")
    click_link("Click here!")
    within("h1.header") do
      assert_equal("FrontPage", text)
    end
    within(".body .section p") do
      assert_equal("FrontPage contents", text)
    end
  end
end

class TestPlainTextRepository < Test::Unit::TestCase
  include Capybara::DSL
  include TestHelper
  include BasicScenario
  include FileUtils

  def setup
    cp_r(fixtures_dir + "plain_data.prepare", fixtures_dir + "plain_data")
    config_path = (fixtures_dir + "hikiconf_plain.rb").expand_path
    Capybara.app = Hiki::App.new(config_path)
  end

  def teardown
    rm_rf(fixtures_dir + "plain_data")
  end
end

