
require "test_helper"
require "hiki/pluginutil"

class TMarshal_Unit_Tests < Test::Unit::TestCase
  def test_methodwords_simple
    assert_equal(["foo"], Hiki::Util.methodwords("foo"))
  end

  def test_methodwords_digit
    assert_equal(["foo", 123], Hiki::Util.methodwords("foo(123)"))
  end

  def test_methodwords_string
    assert_equal(["foo", "0123"], Hiki::Util.methodwords('foo("0123")'))
    assert_equal(["foo", "0123"], Hiki::Util.methodwords(%q|foo('0123')|))
    assert_equal(["foo", "ba&quot;r", %q|a'iueo|], Hiki::Util.methodwords(%Q[foo('ba"r', "a'iueo" )]))
  end

  def test_methodwords_lines
    assert_equal(["foo", "bar", "a\niueo|\nkaki"], Hiki::Util.methodwords(%Q[foo "bar", "a
iueo|
kaki"]))
  end

  def test_methodwords_array
    assert_equal(["foo", [[0, 1], [2, 3]]], Hiki::Util.methodwords(%Q[foo [[0,1],[2,3]]]))
    assert_equal(["foo", "File", ["h]oge", "f[uga"], "bar", [1, 2.0, 0.4]], Hiki::Util.methodwords(%Q[foo File, ["h]oge", "f[uga"], "bar", [1, 2.0, 0.4]]))
  end

  def test_methodwords_nil
    assert_equal(["foo", nil, nil, "hoge"], Hiki::Util.methodwords(%Q[foo nil, nil, "hoge"]))
  end
end
