# $Id: test_interwiki.rb,v 1.2 2005-06-28 05:39:09 fdiary Exp $

require 'test/unit'
require 'hiki/interwiki'

class InterWiki_Unit_Tests < Test::Unit::TestCase
  def setup
    @interwiki = Hiki::InterWiki.new( <<-EOF )
*[[Hiki|http://hikiwiki.org/ja/?]] euc
*[[sf.jp|http://sourceforge.jp/]] alias
EOF
  end

  def test_interwiki_found
    assert_equal( ['http://hikiwiki.org/ja/?FrontPage', 'Hiki:FrontPage'], @interwiki.interwiki( 'Hiki', 'FrontPage' ))
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
