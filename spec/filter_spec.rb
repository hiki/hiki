# Copyright (C) 2008, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2.

require 'spec_helper'

require "tmpdir"
require "fileutils"
require "hiki/command"

describe Hiki::Filter, "when error raised in filtering" do
  before do
    expect(Hiki::Filter).not_to be_respond_to(:clear_filters)
    module Hiki::Filter
      def self.clear_filters
        r = @filters.dup
        @filters.clear
        r
      end
    end
    @original_filters = Hiki::Filter::clear_filters

    Hiki::Filter.add_filter do
      raise "ERROR"
    end

    @conf = double("conf", null_object:true)
    @cgi = double("cgi", null_object:true)
    @plugin = double("plugin", null_object:true)
    @db = double("db", null_object:true)
    Hiki::Filter.init(@conf, @cgi, @plugin, @db)
  end

  after do
    Hiki::Filter::clear_filters
    @original_filters.each do |filter|
      Hiki::Filter.add_filter(&filter)
    end

    class << Hiki::Filter
      undef clear_filters
    end
  end

  it "should through page data without filter raised error" do
    r = nil
    expect{r = Hiki::Filter.new_page_is_spam?("TestPage", "text", "title")}.not_to raise_error
    expect(r).to be_false
  end
end
