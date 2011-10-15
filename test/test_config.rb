# -*- coding: utf-8 -*-

require 'test/unit'
require 'hiki/config'

class Config_Unit_Tests < Test::Unit::TestCase
  def setup
    base_dir = File.dirname(__FILE__)
    @config_path = "#{base_dir}/hikiconf_test.rb"
  end

  def test_initialize
    assert_nothing_raised do
      Hiki::Config.new(@config_path)
    end
  end
end
