# coding: utf-8

require "test_helper"
require "tempfile"

class Plugin_Referer_Unit_Tests < Test::Unit::TestCase
  def setup
    define_dummy_methods
    @body_leave_proc = nil
    @cache_path = test_cache_path
    @options = {}
    @page = "test page"

    plugin_file = File.expand_path(File.join(File.dirname(__FILE__), *%w{.. misc plugin referer.rb}))
    instance_eval(File.open(plugin_file).read)
  end

  def teardown
    FileUtils.rm_r(@test_cache_path) if File.exist?(@test_cache_path)
  end

  def test_body_leave_proc
    assert_nothing_raised do
      @body_leave_proc.call
    end
  end

  def add_body_leave_proc(p)
    @body_leave_proc = p
  end

  def define_dummy_methods
    instance_eval(%{def export_plugin_methods(*args); end})
  end

  def test_cache_path
    if ! defined?(@test_cache_path)
      tempfile = Tempfile.new(self.class.to_s)
      @test_cache_path = File.join(File.dirname(tempfile.path), self.class.to_s)
      FileUtils.mkdir(@test_cache_path) unless File.exist?(@test_cache_path)
      tempfile.close(true)
    end
    @test_cache_path
  end
end
