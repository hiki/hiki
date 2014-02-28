# -*- coding: utf-8 -*-

require "test_helper"

require "rack"
require "hiki/app"

module BasicScenario
  def test_title
    visit("/")
    assert_title("FrontPage")
  end

  def test_get_create
    visit("/?c=create")
    assert_title("Test Wiki - Create")
  end

  def test_multiple_params
    visit("/?FrontPage&foo=bar&buzz=foo")
    assert_title("FrontPage")
  end

  def test_create_new_page
    visit("/?c=create")
    fill_in("key", with: "NewPage")
    click_button("New")
    fill_in("contents", with: "Test Test")
    click_button("Save")
    click_link("Click here!")

    assert_title("NewPage")
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
    fill_in("contents", with: "FrontPage contents")
    click_button("Save")
    click_link("Click here!")
    assert_title("FrontPage")
    within(".body .section p") do
      assert_equal("FrontPage contents", text)
    end
  end

  module Repository
  end
end

class BasicScenario::Repository::TestPlainText < Test::Unit::TestCase
  include Capybara::DSL
  include TestHelper
  include BasicScenario
  include FileUtils

  def setup
    @wiki_data_path = fixtures_dir + "plain_data"
    cp_r(fixtures_dir + "plain_data.prepare", @wiki_data_path)
    config_path = (fixtures_dir + "hikiconf_plain.rb").expand_path
    Capybara.app = Hiki::App.new(config_path)
  end

  def teardown
    rm_rf(@wiki_data_path)
  end
end

class BasicScenario::Repository::TestGit < Test::Unit::TestCase
  include Capybara::DSL
  include TestHelper
  include BasicScenario
  include FileUtils

  def setup
    check_command("git")
    @wiki_data_path = fixtures_dir + "git_data"
    cp_r(fixtures_dir + "plain_data.prepare", @wiki_data_path)
    Dir.chdir(@wiki_data_path.expand_path) do
      system("git", "init", "--quiet", ".")
      system("git", "add", "text")
      system("git", "commit", "--quiet", "-m", "'Initial commit'")
    end
    config_path = (fixtures_dir + "hikiconf_git.rb").expand_path
    Capybara.app = Hiki::App.new(config_path)
  end

  def teardown
    rm_rf(@wiki_data_path)
  end
end

class BasicScenario::Repository::TestHg < Test::Unit::TestCase
  include Capybara::DSL
  include TestHelper
  include BasicScenario
  include FileUtils

  def setup
    check_command("hg")
    @wiki_data_path = fixtures_dir + "hg_data"
    cp_r(fixtures_dir + "plain_data.prepare", @wiki_data_path)
    Dir.chdir(@wiki_data_path.expand_path) do
      system("hg", "init", "--quiet", ".")
      create_hgrc
      system("hg", "add", "--quiet", "text")
      system("hg", "commit", "--quiet", "-m", "'Initial commit'")
    end
    config_path = (fixtures_dir + "hikiconf_hg.rb").expand_path
    Capybara.app = Hiki::App.new(config_path)
  end

  def teardown
    rm_rf(@wiki_data_path)
  end
end

class BasicScenario::Repository::TestSVN < Test::Unit::TestCase
  include Capybara::DSL
  include TestHelper
  include BasicScenario
  include FileUtils

  def setup
    check_command("svn")
    @wiki_data_path = fixtures_dir + "svn_data"
    @wiki_repo_path = fixtures_dir + "svn_repo"
    @wiki_base_data_path = fixtures_dir + "plain_data.prepare"
    cp_r(@wiki_base_data_path, @wiki_data_path)
    system("svnadmin", "create", @wiki_repo_path.expand_path.to_s)
    system("svn", "import", "--quiet", "-m", "'Import initial data'",
           "#{(@wiki_base_data_path + 'text').expand_path}",
           "file://#{@wiki_repo_path.expand_path}")
    Dir.chdir(@wiki_data_path.expand_path) do
      rm_rf(@wiki_data_path + "text")
      system("svn", "checkout", "--quiet",
             "file://#{@wiki_repo_path.expand_path}", "#{@wiki_data_path + 'text'}")
    end
    config_path = (fixtures_dir + "hikiconf_svn.rb").expand_path
    Capybara.app = Hiki::App.new(config_path)
  end

  def teardown
    rm_rf(@wiki_data_path)
    rm_rf(@wiki_repo_path)
  end
end
