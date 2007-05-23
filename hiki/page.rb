# $Id: page.rb,v 1.15 2007-05-23 07:20:04 znz Exp $
# Copyright (C) 2002-2004 TAKEUCHI Hitoshi <hitoshi@namaraii.com>
# Copyright (C) 2004-2005 Kazuhiko <kazuhiko@fdiary.net>

require 'cgi'
require 'nkf'

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
      @template = ''
      @contents = nil
    end

    def to_html
      ERB::new( @template ).result( binding )
    end

    def process( plugin )
      @plugin = plugin
      @body = to_html

      @conf.save_config if @contents[:save_config]
      @headers = Hash::new
      if @contents[:last_modified] and 'HEAD' == @cgi.request_method
        @headers['Last-Modified']    = CGI::rfc1123_date(@contents[:last_modified])
      end
      @headers['type']     = 'text/html'
      if @conf.mobile_agent?
	@body = NKF::nkf( '-sE', @body ) if /EUC-JP/i =~ @conf.charset
	@headers['charset']          = 'Shift_JIS'
      else
	@headers['charset']          = @conf.charset
	@headers['Content-Language'] = @conf.lang
	@headers['Pragma']           = 'no-cache'
	@headers['Cache-Control']    = 'no-cache'
      end
      @headers['Vary']             = 'User-Agent,Accept-Language'
      @headers['Content-Length']   = @body.size.to_s
      @headers['cookie']           = @plugin.cookies unless @plugin.cookies.empty?
    end

    def out( headers = nil )
      @headers.update( headers ) if headers
      print @cgi.header( @headers )
      if @cgi.request_method != 'HEAD'
	print @body
      end
    end
  end
end
