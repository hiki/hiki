# $Id: plugin.rb,v 1.1.1.1 2003-02-22 04:39:31 hitoshi Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>
# You can redistribute it and/or modify it under the terms of
# the Ruby's licence.

require 'cgi'
require 'hiki/util'

module Hiki
  class Plugin
    attr_reader :toc_f
    
    def initialize( options )
      @options      = options
      set_tdiary_env
      
      @header_procs     = []
      @update_procs     = []
      @body_enter_procs = []
      @body_leave_procs = []
      
      @page             = options['page']
      @db               = options['db']
      @cgi              = options['cgi']
      @toc_f            = false
    end

    def header_proc
      return '' unless $use_plugin
      
      r = []
      @header_procs.each do |proc|
        begin
          r << proc.call
        rescue Exception
          r << plugin_error( 'header_proc', $! )
        end
      end
      r.join.chomp
    end

    def update_proc
    end

    def body_enter_proc
      return '' unless $use_plugin

      r = []
      @body_enter_procs.each do |proc|
        begin
          r << proc.call( @date )
        rescue Exception
          r << plugin_error( 'body_enter_proc', $! )
        end
      end
      r.join
    end

    def body_leave_proc
      return '' unless $use_plugin
      r = []

      @body_leave_procs.each do |proc|
        begin
          r << proc.call( @date )
        rescue Exception
          r << plugin_error( 'body_leave_proc', $! )
        end
      end
      r.join
    end

    def add_cookie( cookie )
      @cookies << cookie
    end

  private
    def add_header_proc( block = proc )
      @header_procs << block
    end

    def add_update_proc( block = proc )
      @update_procs << block
    end

    def add_body_enter_proc( block = proc )
      @body_enter_procs << block
    end

    def add_body_leave_proc( block = proc )
      @body_leave_procs << block
    end

    def set_tdiary_env
      @date             = Time::now
      @cookies          = []
      
      @options['cache_path']  = $cache_path 
      @options['mode']        = "latest"
#      @options['author_name'] = $author_name || 'anonymous'
#      @options['author_mail'] = $mail
#      @options['index_page']  = $index_page
#      @options['html_title']  = $site_name
      @options['years']       = {}
      @options['diaries']     = nil,
      @options['date']        = Time::now
 
      %w(cache_path mode years diaries date).each do |p|
        eval("@#{p} = @options['#{p}']")
      end
    end
  end
end
