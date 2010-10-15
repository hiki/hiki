# -*- coding: utf-8 -*-
# $Id$

$:.unshift(File.join(File.dirname(__FILE__), %w{..}))

require 'test/unit'
require 'hiki/config'

class Config_Unit_Tests < Test::Unit::TestCase
  def test_initialize
    assert_nothing_raised do
      Hiki::Config.new
    end
  end
end
