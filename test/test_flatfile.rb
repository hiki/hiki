# coding: utf-8

require 'test/unit'
require 'hiki/db/flatfile'
require 'fileutils'
require 'tempfile'


class HikiDB_flatfile_Unit_Tests < Test::Unit::TestCase
  def setup
    @db = Hiki::HikiDB_flatfile.new(stub_conf)
  end

  def teardown
    FileUtils.rm_r(test_data_path) if File.exists?(test_data_path)
  end

  def test_close_db
    assert(@db.close_db)
  end

  def stub_conf
    if ! defined?(@stub_conf)
      @stub_conf = Object.new
      @stub_conf.instance_eval(%{def data_path; "#{test_data_path}"; end})
    end
    @stub_conf
  end

  def test_data_path
    @test_data_path ||= File.join(tempdir, self.class.to_s)
  end

  def tempdir
    if ! defined?(@tempdir)
      tempfile = Tempfile.new(self.class.to_s + Time.now.to_i.to_s)
      @tempdir = File.dirname(tempfile.path)
      FileUtils.mkdir(@tempdir) unless File.exists?(@tempdir)
      tempfile.close(true)
    end
    @tempdir
  end
end