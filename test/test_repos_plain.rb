require 'test/unit'
require 'fileutils'
require 'hiki/repos/plain'
require 'hiki/util'

class Repos_Plain_Tests < Test::Unit::TestCase
  def setup
    @tmpdir = '__tmp-wikitest'
    @root = "#{@tmpdir}/root"
    @wiki = 'wikiwiki'
    @data_path = "#{@tmpdir}/data"
    @repos = Hiki::ReposPlain.new(@root, @data_path)

    FileUtils.mkdir_p("#{@root}/#{@wiki}")
    FileUtils.mkdir_p("#{@data_path}/text")
    mkfile("#{@data_path}/text/.wiki", @wiki)
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_commit
    FileUtils.mkdir("#{@root}/#{@wiki}/HogeHoge")
    FileUtils.mkdir("#{@root}/#{@wiki}/FooBar")
    mkfile("#{@root}/#{@wiki}/HogeHoge/1", 'hogehoge')
    mkfile("#{@root}/#{@wiki}/FooBar/1", 'foobar')

    mkfile("#{@data_path}/text/HogeHoge", 'hogehoge')
    mkfile("#{@data_path}/text/FooBar", 'foobar new')

    @repos.commit('FooBar')
    
    assert_equal('foobar', File.read("#{@root}/#{@wiki}/FooBar/1"))
    assert_equal('foobar new', File.read("#{@root}/#{@wiki}/FooBar/2"))
  end

  def test_get_revision
    FileUtils.mkdir("#{@root}/#{@wiki}/HogeHoge")
    FileUtils.mkdir("#{@root}/#{@wiki}/FooBar")
    mkfile("#{@root}/#{@wiki}/HogeHoge/1", 'hogehoge1')
    mkfile("#{@root}/#{@wiki}/FooBar/1", 'foobar1')

    mkfile("#{@root}/#{@wiki}/HogeHoge/2", 'hogehoge2')
    mkfile("#{@root}/#{@wiki}/FooBar/2", 'foobar2')

    mkfile("#{@root}/#{@wiki}/HogeHoge/3", 'hogehoge3')
    mkfile("#{@root}/#{@wiki}/FooBar/3", 'foobar3')

    assert_equal('hogehoge1', @repos.get_revision('HogeHoge', 1))
    assert_equal('hogehoge2', @repos.get_revision('HogeHoge', 2))
    assert_equal('hogehoge3', @repos.get_revision('HogeHoge', 3))
  end

  def test_revisions
    FileUtils.mkdir("#{@root}/#{@wiki}/HogeHoge")
    mkfile("#{@root}/#{@wiki}/HogeHoge/1", 'hogehoge1')
    mkfile("#{@root}/#{@wiki}/HogeHoge/2", 'hogehoge2')
    mkfile("#{@root}/#{@wiki}/HogeHoge/3", 'hogehoge3')

    s = Time.now.localtime.to_s
    expected = [
      [3, s, '', ''],
      [2, s, '', ''],
      [1, s, '', ''],
      ]

    assert_equal(expected, @repos.revisions('HogeHoge'))
  end

  private
  def mkfile(file, contents)
    File.open(file, 'w') do |f|
      f.print contents
    end
  end
end
