
require "test_helper"
require "hiki/aliaswiki"

class AliasWiki_Unit_Tests < Test::Unit::TestCase
  def setup
    @aliaswiki = Hiki::AliasWiki.new("*[[orig_name:alias_name]]")
  end

  def test_aliaswiki_found
    assert_equal("alias_name", @aliaswiki.aliaswiki("orig_name"))
  end

  def test_aliaswiki_not_found
    assert_equal("page_name", @aliaswiki.aliaswiki("page_name"))
  end

  def test_original_name_found
    assert_equal("orig_name", @aliaswiki.original_name("alias_name"))
  end

  def test_original_name_not_found
    assert_equal("page_name", @aliaswiki.original_name("page_name"))
  end
end
