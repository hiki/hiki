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
end
