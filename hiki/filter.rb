# Copyright (C) 2008, KURODA Hiraku <hiraku@hinet.mydns.jp>
# You can redistribute it and/or modify it under GPL2.

module Hiki
  module Filter
    class PageData
      attr_reader :page, :text, :title, :keyword, :remote_addr
      def initialize(page=nil, text=nil, title=nil, keyword=nil, remote_addr=nil)
        @page = page
        @text = text
        @title = title==page ? nil : title
        keyword = keyword.split("\n") if keyword.is_a?(String)
        @keyword = keyword || []
        @remote_addr = remote_addr
      end

      def title
        @title || @page
      end
    end

    def self.require_filters
      dir = File.dirname(__FILE__)
      Dir["#{dir}/filter/*_filter.rb"].each do |f|
        next unless n = f[/\A#{Regexp.escape(dir)}\/filter\/(.*_filter)\.rb\z/, 1]
        require "hiki/filter/#{n}"
      end
    end

    def self.init(conf, request, plugin, db)
      @conf = conf
      @request = request
      @plugin = plugin
      @db = db
    end

    def self.plugin; @plugin; end

    def self.add_filter(&proc)
      @filters ||= []
      @filters << proc if proc
    end

    def self.new_page_is_spam?(page, text, title=nil)
      posted_by_user = @plugin.user and not @plugin.user.empty?

      title = @db.get_attribute(page, :title) || "" unless title
      title = page if title.empty?
      new_page = PageData.new(page,
                              text.gsub(/\r\n/, "\n"),
                              title,
                              (@request.params["keyword"] || "").gsub(/\r\n/, "\n").split(/\n/),
                              @request.remote_addr)

      old_title = @db.get_attribute(page, :title) || ""
      old_title = page if old_title.empty?
      old_page = PageData.new(page, @db.load(page)||"", old_title, @db.get_attribute(page, :keyword)||[])

      is_spam = false
      @filters.each do |proc|
        begin
          is_spam ||= proc.call(new_page, old_page, posted_by_user)
        rescue Exception
        end
      end
      return !posted_by_user && is_spam
    end
  end
end

Hiki::Filter.require_filters
