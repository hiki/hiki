# $Id: page.rb,v 1.4 2004-02-15 02:48:35 hitoshi Exp $
# Copyright (C) 2002-2004 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

require 'cgi'

module Hiki
  class Page
    attr_accessor :template, :contents
    
    def initialize(cgi)
      @cgi = cgi
      @template = nil
      @contents = nil
    end

    def to_html
      tmpl = TemplateFile.new @template
      html = ''
#      tmpl = TemplateFileWithCache[@template]
#      tmpl.use_compiler = true
#      tmpl.set_hint_by_sample_data(@contents)
      tmpl.expand_attr = true
      tmpl.expand(html, @contents)
      html
    end

    def page( plugin )
      $title = @contents[:title]
      @contents[:header]         = plugin.header_proc.sanitize
      @contents[:body_leave]     = plugin.body_leave_proc.sanitize
      @contents[:footer]         = plugin.footer_proc.sanitize
      
      html = to_html
      header = Hash::new
# XREA
#      if @contents[:last_modified] and /HEAD/i =~ @cgi.request_method
#       header['Last-Modified']    = CGI::rfc1123_date(@contents[:last_modified])
#      end
      header['Last-Modified']    = CGI::rfc1123_date(@contents[:last_modified])
      header['type']     = 'text/html'
      header['charset']          = $charset
      header['Content-Length']   = html.size.to_s
      header['Content-Language'] = $lang
      header['Pragma']           = 'no-cache'
      header['Cache-Control']    = 'no-cache'
      response = @cgi.header(header)
      response += html if /HEAD/i !~ @cgi.request_method
      response
    end
  end
end
