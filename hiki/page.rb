# $Id: page.rb,v 1.15 2007-05-23 07:20:04 znz Exp $
# Copyright (C) 2002-2004 TAKEUCHI Hitoshi <hitoshi@namaraii.com>
# Copyright (C) 2004-2005 Kazuhiko <kazuhiko@fdiary.net>

require 'cgi' unless Object.const_defined?(:Rack)
require 'nkf'

module Hiki
  class Page
    begin
      require 'erb_fast'
    rescue LoadError
      require 'erb'
    end

    attr_accessor :command, :template, :contents

    def initialize(request, conf)
      @request = request
      @conf = conf
      @layout = @conf.read_layout
      @command  = nil
      @template = ''
      @contents = nil
    end

    def to_html
      method_name = "render_#{@command}"
      unless respond_to?(:layout)
        erb = ERB.new(@layout)
        erb.def_method(self.class, "render_layout", "layout.html")
      end
      unless respond_to?(method_name)
        erb = ERB.new(@template)
        erb.def_method(self.class, method_name, "#{@command}.html")
      end
      render_layout{ __send__(method_name) }
    end

    def process( plugin )
      @plugin = plugin
      @body = to_html

      @conf.save_config if @contents[:save_config]
      @headers = {}
      if @contents[:last_modified] and 'HEAD' == @request.request_method
        @headers['Last-Modified']    = CGI.rfc1123_date(@contents[:last_modified])
      end
      @headers['type']     = 'text/html'
      if @conf.mobile_agent?
        @body = NKF.nkf( '-sE', @body ) if /EUC-JP/i =~ @conf.charset
        @headers['charset']          = 'Shift_JIS'
      else
        @headers['charset']          = @conf.charset
        @headers['Content-Language'] = @conf.lang
        @headers['Pragma']           = 'no-cache'
        @headers['Cache-Control']    = 'no-cache'
      end
      @headers['Vary']             = 'User-Agent,Accept-Language'
      @headers['Content-Length']   = @body.bytesize.to_s rescue @body.size.to_s
      @headers['cookie']           = @plugin.cookies unless @plugin.cookies.empty?
    end

    def out( headers = nil )
      @headers.update( headers ) if headers
      response = Hiki::Response.new(@body, 200, @headers)
      if Object.const_defined?(:Rack)
        cookies = @headers.delete('cookie')
        if cookies
          cookies.each do |cookie|
            response.set_cookie(cookie.name, cookie.value)
          end
        end
      end
      response
    end
  end
end
