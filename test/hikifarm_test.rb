require 'test_helper'
load "#{File.dirname(__FILE__)}/../misc/hikifarm/index.cgi"

class Wiki_Unit_Tests < Test::Unit::TestCase
  def setup
    @data_root = '__tmp-wikitest'
    name = 'foo'
    FileUtils.mkdir_p("#{@data_root}/#{name}/text")
    Dir.chdir("#{@data_root}/#{name}/text") do
      File.open('FrontPage', 'w'){|f| f.puts "frontpage"}
      sleep 1
      File.open('SandBox', 'w'){|f| f.puts "sandbox"}
      @now = Time.now
    end
    File.open("#{@data_root}/#{name}/hiki.conf", 'w'){|f| f.puts '@site_name = "FooBar"'}

    @wiki = Wiki.new(name, @data_root)
  end

  def teardown
    FileUtils.rm_rf(@data_root)
  end

  def test_name
    assert_equal('foo', @wiki.name)
  end

  def test_title
    assert_equal('FooBar', @wiki.title)
  end

  def test_mtime
    assert_equal(@now.to_i, @wiki.mtime.to_i)
  end

  def test_last_modified_page
    assert_equal('SandBox', @wiki.last_modified_page)
  end

  def test_pages_num
    assert_equal(2, @wiki.pages_num)
  end
end

class Hikifarm_Unit_Tests < Test::Unit::TestCase
  def setup
    @farm_pub_path = '__tmp-farmtest-pub'
    @data_root = '__tmp-wikitest'
    setup_wiki('foo', 'FrontPage', 'SandBox', 'HogeHoge')
    setup_wiki('bar', 'FrontPage', 'SandBox')
    setup_wiki('hoge', 'FrontPage', 'SandBox', 'aaa', 'bbb')

    @farm = Hikifarm.new(@farm_pub_path, '/usr/bin/ruby', 'default', nil, @data_root)
  end

  def setup_wiki(name, *pages)
    FileUtils.mkdir_p("#{@data_root}/#{name}/text")
    Dir.chdir("#{@data_root}/#{name}/text") do
      pages.each do |page|
        File.open(page, 'w'){|f| f.puts page}
      end
    end
    File.open("#{@data_root}/#{name}/hiki.conf", 'w') do |f|
      f.puts %Q!@site_name = "#{name.upcase}"!
    end

    FileUtils.mkdir_p("#{@farm_pub_path}/#{name}")
    File.open("#{@farm_pub_path}/#{name}/hikiconf.rb", 'w'){|f| }
  end

  def teardown
    FileUtils.rm_rf(@data_root)
    FileUtils.rm_rf(@farm_pub_path)
  end

  def test_wikis_num
    assert_equal(3, @farm.wikis_num)
  end

  def test_pages_num
    assert_equal(9, @farm.pages_num)
  end

  def test_create_wiki
    name = 'newwiki'
    default_pages_path = 'data/text'
    @farm.create_wiki(name, '', 'index.cgi', nil, @data_root, default_pages_path)

    default_pages = Dir["#{default_pages_path}/*"].delete_if{|f| !File.file?(f.untaint)}.map{|e| File.basename(e)}
    copied_pages = Dir["#{@data_root}/#{name}/text/*"].delete_if{|f| !File.file?(f.untaint)}.map{|e| File.basename(e)}
    assert_equal(default_pages.sort, copied_pages.sort)

    Dir["#{default_pages_path}/*"].each do |orig|
      orig.untaint
      next if not File.file?(orig)
      copy = "#{@data_root}/#{name}/text/#{File.basename(orig)}"
      assert(File.exist?(copy))
      assert_equal(File.read(orig), File.read(copy))
    end
  end
end
