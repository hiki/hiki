# $Id: page.rb,v 1.3 2003-03-23 03:37:12 hitoshi Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

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
#      tmpl = TemplateFileWithCache[template]
#      tmpl.use_compiler = true
#      tmpl.set_hint_by_sample_data(data)
      tmpl.expand_attr = true
      tmpl.expand(html, @contents)
      html
    end

    def page( plugin, last_modified )
      @contents[:header]         = plugin.header_proc.sanitize
      @contents[:body_leave]     = plugin.body_leave_proc.sanitize
      html = to_html
      header = Hash::new
      header['Last-Modified']    = CGI::rfc1123_date(last_modified) if last_modified
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
