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

