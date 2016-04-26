# To do: Handle Exception raised in Time.parse line 92

require "test_helper"
require "time"
require "cgi/util"
require "rack"

require "hiki/request"
require "hiki/response"

class Plugin_RSS_Unit_Tests < Test::Unit::TestCase
  def setup
    @now = Time.parse(CGI.rfc1123_date(Time.now))
    @request = Object.new
    stub(@request).params.returns({})
    @conf = Object.new
    stub(@conf).charset
    stub(@conf).lang
    plugin_file = File.expand_path(File.join(File.dirname(__FILE__), *%w{.. misc plugin rss.rb}))
    instance_eval(File.read(plugin_file))
    class << self
      define_method(:rss_body) {|*page_num|
        ["", @now]
      }
    end

    ARGV << " " # dummy argment for CGI offline mode
  end

  def test_rss_returns_304_when_if_modified_since_is_same_to_last_modified
    ENV["HTTP_IF_MODIFIED_SINCE"] = CGI.rfc1123_date(@now)
    assert_equal(304, rss.status)
  end

  def add_body_enter_proc(prcedure)
  end

  def add_header_proc(procedure)
  end

  def add_conf_proc(plugin_name, procedure)
  end

  def export_plugin_methods(*args)
  end

  def label_rss_config
  end
end
