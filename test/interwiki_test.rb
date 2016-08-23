# -*- coding: utf-8 -*-

require "test_helper"
require "hiki/interwiki"

class InterWiki_Unit_Tests < Test::Unit::TestCase
  def setup
    @interwiki = Hiki::InterWiki.new(<<-EOF )
*[[Hiki|http://hikiwiki.org/ja/?]] euc
*[[Siki|http://hikiwiki.org/ja/?]] sjis
*[[Uiki|http://hikiwiki.org/ja/?]] utf8
*[[sf.jp|http://sourceforge.jp/]] alias
EOF
  end

  def test_interwiki_found
    assert_equal(["http://hikiwiki.org/ja/?FrontPage", "Hiki:FrontPage"],
                 @interwiki.interwiki("Hiki", "FrontPage"))
  end

  def test_interwiki_found_euc
    assert_equal(["http://hikiwiki.org/ja/?%A5%D5%A5%ED%A5%F3%A5%C8%A5%DA%A1%BC%A5%B8",
                  "Hiki:フロントページ"],
                 @interwiki.interwiki("Hiki", "フロントページ"))
  end

  def test_interwiki_found_sjis
    assert_equal(["http://hikiwiki.org/ja/?%83t%83%8D%83%93%83g%83y%81%5B%83W",
                  "Siki:フロントページ"],
                 @interwiki.interwiki("Siki", "フロントページ"))
  end

  def test_interwiki_found_utf8
    assert_equal(["http://hikiwiki.org/ja/?%E3%83%95%E3%83%AD%E3%83%B3%E3%83%88%E3%83%9A%E3%83%BC%E3%82%B8",
                  "Uiki:フロントページ"],
                 @interwiki.interwiki("Uiki", "フロントページ"))
  end

  def test_interwiki_not_found
    assert_equal(nil, @interwiki.interwiki("foo", "bar"))
  end

  def test_outer_alias_found
    assert_equal(["http://sourceforge.jp/", "sf.jp"], @interwiki.outer_alias("sf.jp"))
  end

  def test_outer_alias_not_found
    assert_equal(nil, @interwiki.outer_alias("sf.net"))
  end
end
