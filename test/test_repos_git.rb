require 'test/unit'
require 'fileutils'
require 'hiki/repos/git'
require 'hiki/util'

class Repos_Git_Tests < Test::Unit::TestCase
  def setup
    @tmp_dir = File.join(File.dirname(__FILE__), "tmp")
    @root = "#{@tmp_dir}/root"
    @wiki = 'wikiwiki'
    @data_dir = "#{@tmp_dir}/data"
    @text_dir = "#{@data_dir}/text"
    @repos = Hiki::ReposGit.new(@root, @data_dir)

    FileUtils.mkdir_p(@text_dir)
    Dir.chdir(@text_dir) do
      git("init")
    end
  end

  def teardown
    FileUtils.rm_rf(@tmp_dir)
  end

  def test_commit
    write("FooBar", 'foobar')
    @repos.commit('FooBar')
    assert_equal('foobar', read('FooBar'))
    object = nil
    Dir.chdir(@text_dir) do
      object = git("hash-object", "FooBar")
    end

    write("FooBar", 'foobar new')
    @repos.commit('FooBar')
    assert_equal('foobar new', read('FooBar'))

    Dir.chdir(@text_dir) do
      assert_equal("foobar", git("cat-file", "blob", object))
    end
  end

  def test_get_revision
    rev1 = rev2 = rev3 = nil
    write("HogeHoge", 'hogehoge1')
    Dir.chdir(@text_dir) {git("add", "HogeHoge")}
    Dir.chdir(@text_dir) {git("commit", "-m", "First", "HogeHoge")}
    Dir.chdir(@text_dir) {rev1 = git("hash-object", "HogeHoge")}
    write("HogeHoge", 'hogehoge2')
    Dir.chdir(@text_dir) {git("commit", "-m", "Second", "HogeHoge")}
    Dir.chdir(@text_dir) {rev2 = git("hash-object", "HogeHoge")}
    write("HogeHoge", 'hogehoge3')
    Dir.chdir(@text_dir) {git("commit", "-m", "Third", "HogeHoge")}
    Dir.chdir(@text_dir) {rev3 = git("hash-object", "HogeHoge")}

    assert_equal('hogehoge1', @repos.get_revision('HogeHoge', rev1[0, 7]))
    assert_equal('hogehoge2', @repos.get_revision('HogeHoge', rev2[0, 7]))
    assert_equal('hogehoge3', @repos.get_revision('HogeHoge', rev3[0, 7]))
  end

  def test_revisions
    rev1 = rev2 = rev3 = nil
    write("HogeHoge", 'hogehoge1')
    Dir.chdir(@text_dir) {git("add", "HogeHoge")}
    Dir.chdir(@text_dir) {git("commit", "-m", "First", "HogeHoge")}
    Dir.chdir(@text_dir) {rev1 = git("hash-object", "HogeHoge")}
    write("HogeHoge", 'hogehoge2')
    Dir.chdir(@text_dir) {git("commit", "-m", "Second", "HogeHoge")}
    Dir.chdir(@text_dir) {rev2 = git("hash-object", "HogeHoge")}
    write("HogeHoge", 'hogehoge3')
    Dir.chdir(@text_dir) {git("commit", "-m", "Third", "HogeHoge")}
    Dir.chdir(@text_dir) {rev3 = git("hash-object", "HogeHoge")}

    modified = Time.now.localtime.strftime('%Y/%m/%d %H:%M:%S')
    expected = [
                [rev3[0, 7], modified, '', 'Third'],
                [rev2[0, 7], modified, '', 'Second'],
                [rev1[0, 7], modified, '', 'First'],
               ]

    assert_equal(expected, @repos.revisions('HogeHoge'))
  end

  private
  def git(*args)
    args = args.collect{|arg| arg.dump}.join(' ')
    result = `git #{args}`.chomp
    raise result unless $?.success?
    result
  end

  def file_name(page)
    "#{@data_dir}/text/#{page}"
  end

  def write(page, content)
    File.open(file_name(page), "wb") do |f|
      f.print(content)
    end
  end

  def read(page)
    File.open(file_name(page), "rb") do |f|
      f.read
    end
  end
end
