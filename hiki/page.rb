# $Id: page.rb,v 1.6 2005-01-28 04:35:29 fdiary Exp $
# Copyright (C) 2002-2004 TAKEUCHI Hitoshi <hitoshi@namaraii.com>
# Copyright (C) 2004-2005 Kazuhiko <kazuhiko@fdiary.net>

require 'cgi'

module Hiki
  class Page
    begin
      require 'erb_fast'
    rescue LoadError
      require 'erb'
    end

    attr_accessor :template, :contents
    
    def initialize(cgi, conf)
      @cgi = cgi
      @conf = conf
      @template = nil
      @contents = nil
    end

    def to_html
      ERB::new( File::open( @template ){|f| f.read}.untaint ).result( binding )
    end

    def page( plugin )
      plugin.title = @contents[:title]
      @plugin = plugin
      @contents[:lang]           = @conf.lang
      @contents[:header]         = plugin.header_proc.sanitize
      @contents[:body_leave]     = plugin.body_leave_proc.sanitize
      @contents[:footer]         = plugin.footer_proc.sanitize
      
      html = to_html
      @conf.save_config if @cgi.params['saveconf'][0]
      header = Hash::new
      if @contents[:last_modified] and /HEAD/i =~ @cgi.request_method
	header['Last-Modified']    = CGI::rfc1123_date(@contents[:last_modified])
      end
      header['type']     = 'text/html'
      header['charset']          = @conf.charset
      header['Content-Length']   = html.size.to_s
      header['Content-Language'] = @conf.lang
      header['Pragma']           = 'no-cache'
      header['Cache-Control']    = 'no-cache'
      response = @cgi.header(header)
      response += html if /HEAD/i !~ @cgi.request_method
      response
    end
  end
end
