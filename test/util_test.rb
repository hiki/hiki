# -*- coding: utf-8 -*-

require "test_helper"
require "hiki/util"

class TestUtil < Test::Unit::TestCase
  include Hiki::Util

  def setup
    @t1 = "123\n456\n"
    @t2 = "123\nabc\n456\n"
    @t3 = "123\n456\ndef\n"
    @t4 = "こんにちは、私の名前はわたなべです。\n私はJust Another Ruby Porterです。"
    @t5 = "こんばんは、私の名前はまつもとです。\nRubyを作ったのは私です。私はRuby Hackerです。"
    @conf = Object.new
  end

  def test_word_diff_html
    assert_equal("123\n<ins class=\"added\">abc</ins>\n456\n", word_diff(@t1, @t2))
    assert_equal("<del class=\"deleted\">こんにちは</del><ins class=\"added\">こんばんは</ins>、私の<del class=\"deleted\">名前はわたなべです</del><ins class=\"added\">名前はまつもとです</ins>。\n<ins class=\"added\">Rubyを作ったのは私です。</ins>私は<del class=\"deleted\">Just Another </del>Ruby <del class=\"deleted\">Porter</del><ins class=\"added\">Hacker</ins>です。", word_diff(@t4, @t5))
  end

  def test_word_diff_text
    assert_equal("123\n{+abc+}\n456\n", word_diff_text(@t1, @t2))
    assert_equal("[-こんにちは-]{+こんばんは+}、私の[-名前はわたなべです-]{+名前はまつもとです+}。\n{+Rubyを作ったのは私です。+}私は[-Just Another -]Ruby [-Porter-]{+Hacker+}です。", word_diff_text(@t4, @t5))
  end

  def test_unified_diff
    assert_equal("@@ -1,2 +1,3 @@\n 123\n+abc\n 456\n", unified_diff(@t1, @t2))
    assert_equal("@@ -1,3 +1,2 @@\n 123\n-abc\n 456\n", unified_diff(@t2, @t1))
  end

  def test_plugin_error
    error = Object.new
    mock(error).class.returns("Hiki::PluginError")
    mock(error).message.returns("Plugin Error")
    mock(@conf).plugin_debug.returns(false)
    assert_equal("<strong>Hiki::PluginError (Plugin Error): do_something</strong><br>",
                 plugin_error("do_something", error))
  end

  def test_plugin_error_with_debug
    error = Object.new
    mock(error).class.returns("Hiki::PluginError")
    mock(error).message.returns("Plugin Error")
    mock(error).backtrace.returns(["backtrace1", "backtrace2", "backtrace3"])
    mock(@conf).plugin_debug.returns(true)
    assert_equal(<<STR.chomp, plugin_error("do_something", error))
<strong>Hiki::PluginError (Plugin Error): do_something</strong><br><strong>backtrace1<br>
backtrace2<br>
backtrace3</strong>
STR
  end

  def test_cmdstr
    assert_equal("?c=hoge;fuga", cmdstr("hoge", "fuga"))
  end

  def test_title
    mock(@conf).site_name.returns("<TestSite>")
    assert_equal("&lt;TestSite&gt; - FrontPage", title("FrontPage"))
  end

  def test_view_title
    mock(@conf).cgi_name.returns("hiki.cgi")
    assert_equal(%Q!<a href="hiki.cgi?c=search;key=FrontPage">FrontPage</a>!, view_title("FrontPage"))
  end

  def test_format_date
    mock(@conf).msg_time_format.returns("%Y-%m-%d #DAY# %H:%M:%S")
    mock(@conf).msg_day.returns(%w(日 月 火 水 木 金 土))
    assert_equal("2011-01-01 (土) 01:02:03", format_date(Time.mktime(2011, 1, 1, 1, 2, 3)))
  end

  def test_escape
    expected = [
      "%E3%81%82%E3%81%84%E3%81%86%E3%81%88%E3%81%8A",
      "%E3%83%95%E3%83%AD%E3%83%B3%E3%83%88%E3%83%9A%E3%83%BC%E3%82%B8",
      "%A4%A2%A4%A4%A4%A6%A4%A8%A4%AA",
      "%A5%D5%A5%ED%A5%F3%A5%C8%A5%DA%A1%BC%A5%B8",
      "%82%A0%82%A2%82%A4%82%A6%82%A8",
      "%83t%83%8D%83%93%83g%83y%81%5B%83W",
    ]
    actual = [
      "あいうえお",
      "フロントページ",
      NKF.nkf("-m0 -We", "あいうえお"),
      NKF.nkf("-m0 -We", "フロントページ"),
      NKF.nkf("-m0 -Ws", "あいうえお"),
      NKF.nkf("-m0 -Ws", "フロントページ"),
    ]
    assert_equal(expected, actual.map{|v| escape(v) })
  end
end
