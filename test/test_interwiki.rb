# $Id: test_interwiki.rb,v 1.1 2005-06-15 03:10:16 fdiary Exp $

require 'test/unit'
require 'hiki/interwiki'

class InterWiki_Unit_Tests < Test::Unit::TestCase
  def setup
    @interwiki = Hiki::InterWiki.new( <<-EOF )
*[[Hiki|http://www.namaraii.com/hiki/?]] euc
*[[sf.jp|http://sourceforge.jp/]] alias
EOF
  end

  def test_interwiki_found
    assert_equal( ['http://www.namaraii.com/hiki/?FrontPage', 'Hiki:FrontPage'], @interwiki.interwiki( 'Hiki', 'FrontPage' ))
  end

  def test_interwiki_not_found
    assert_equal( nil, @interwiki.interwiki( 'foo', 'bar' ))
  end

  def test_outer_alias_found
    assert_equal( ['http://sourceforge.jp/', 'sf.jp'], @interwiki.outer_alias( 'sf.jp' ))
  end

  def test_outer_alias_not_found
    assert_equal( nil, @interwiki.outer_alias( 'sf.net' ))
  end
end
