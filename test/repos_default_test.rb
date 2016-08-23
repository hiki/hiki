require "test_helper"
require "hiki/util"
require "hiki/repository/default"

class Repos_Default_Tests < Test::Unit::TestCase
  def setup
    @data_path = "__tmp-wikitest"
    @repos = Hiki::Repository::Default.new(nil, @data_path)
    @page_name = "HogeHoge"

    require "fileutils"
    FileUtils.mkdir_p("#{@data_path}/text")
    FileUtils.mkdir_p("#{@data_path}/backup")

    File.open("#{@data_path}/text/#{@page_name}", "w") do |f|
      f.print "new file"
    end

    File.open("#{@data_path}/backup/#{@page_name}", "w") do |f|
      f.print "old file"
    end
    @now = Time.now
  end

  def teardown
    FileUtils.rm("#{@data_path}/text/#{@page_name}")
    FileUtils.rm("#{@data_path}/backup/#{@page_name}")
    FileUtils.rmdir("#{@data_path}/text")
    FileUtils.rmdir("#{@data_path}/backup")
    FileUtils.rmdir(@data_path)
  end

  def test_get_revision
    assert_equal("old file", @repos.get_revision(@page_name, 1))
    assert_equal("new file", @repos.get_revision(@page_name, 2))
  end

  def test_revisions
    revs = [
      [2, @now.localtime.strftime("%Y/%m/%d %H:%M:%S"), "", "current"],
      [1, @now.localtime.strftime("%Y/%m/%d %H:%M:%S"), "", "backup"]
    ]
    assert_equal(revs, @repos.revisions(@page_name))
  end
end
