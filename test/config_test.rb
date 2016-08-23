# -*- coding: utf-8 -*-

require "test_helper"
require "hiki/config"

class Config_Unit_Tests < Test::Unit::TestCase
  def setup
    base_dir = File.dirname(__FILE__)
    @config_path = "#{base_dir}/fixtures/hikiconf_unit.rb"
  end

  def test_initialize
    assert_nothing_raised do
      Hiki::Config.new(@config_path)
    end
  end
end
