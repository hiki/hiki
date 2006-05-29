# $Id: test_util.rb,v 1.4 2006-05-29 13:39:10 fdiary Exp $

$KCODE = 'e'

$:.unshift(File.join(File.dirname(__FILE__), '../hiki'))

require 'test/unit'
require 'hiki/util'

class TMarshal_Unit_Tests < Test::Unit::TestCase
  include Hiki::Util

  def setup
    @t1 = "123\n456\n"
    @t2 = "123\nabc\n456\n"
    @t3 = "123\n456\ndef\n"
    @t4 = "こんにちは、私の名前はわたなべです。\n私はJust Another Ruby Porterです。"
    @t5 = "こんばんは、私の名前はまつもとです。\nRubyを作ったのは私です。私はRuby Hackerです。"
    @d1 = Document.new( @t1, 'EUC-JP', 'LF' )
    @d2 = Document.new( @t2, 'EUC-JP', 'LF' )
    @d3 = Document.new( @t3, 'EUC-JP', 'LF' )
    @d4 = Document.new( @t4, 'EUC-JP', 'LF' )
    @d5 = Document.new( @t5, 'EUC-JP', 'LF' )
  end

  def test_word_diff_html
    assert_equal( "123\n<ins class=\"added\">abc</ins>\n456\n", word_diff( @t1, @t2 ) )
    assert_equal( "<del class=\"deleted\">こんにちは</del><ins class=\"added\">こんばんは</ins>、私の<del class=\"deleted\">名前はわたなべです</del><ins class=\"added\">名前はまつもとです</ins>。\n<ins class=\"added\">Rubyを作ったのは私です。</ins>私は<del class=\"deleted\">Just Another </del>Ruby <del class=\"deleted\">Porter</del><ins class=\"added\">Hacker</ins>です。", word_diff( @t4, @t5) )
  end

  def test_word_diff_text
    assert_equal( "123\n{+abc+}\n456\n", word_diff_text( @t1, @t2 ) )
    assert_equal( "[-こんにちは-]{+こんばんは+}、私の[-名前はわたなべです-]{+名前はまつもとです+}。\n{+Rubyを作ったのは私です。+}私は[-Just Another -]Ruby [-Porter-]{+Hacker+}です。", word_diff_text( @t4, @t5 ) )
  end

  def test_unified_diff
    assert_equal( "@@ -1,2 +1,3 @@\n 123\n+abc\n 456\n", unified_diff( @t1, @t2 ) )
    assert_equal( "@@ -1,3 +1,2 @@\n 123\n-abc\n 456\n", unified_diff( @t2, @t1 ) )
  end

  def test_euc_to_utf8
    assert_equal( "\343\201\273\343\201\222", euc_to_utf8( 'ほげ' ) )
    assert_equal( "\343\200\234", euc_to_utf8( '〜' ) )
  end

  def test_utf8_to_euc
    assert_equal( 'ほげ', utf8_to_euc( "\343\201\273\343\201\222" ) )
    assert_equal( '〜', utf8_to_euc( "\343\200\234" ) )
  end
end
