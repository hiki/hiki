# Copyright (C) 2002-2004 TAKEUCHI Hitoshi <hitoshi@namaraii.com>
# Copyright (C) 2004-2005 Kazuhiko <kazuhiko@fdiary.net>

require "cgi" unless Object.const_defined?(:Rack)
require "cgi/util"
require "nkf"

module Hiki
  class Page
    begin
      require "erb_fast"
    rescue LoadError
      require "erb"
    end

    attr_accessor :command, :template, :contents

    def initialize(request, conf)
      @request = request
      @conf = conf
      @layout = @conf.read_layout
      @command  = nil
      @template = ""
      @contents = nil
    end

    def to_html
      if @conf.mobile_agent?
        content_method_name = "render_mobile_#{@command}"
        content_name = "i.#{@command}.html"
        layout_method_name = "render_mobile_layout"
        layout_name = "i.layout.html"
      else
        content_method_name = "render_#{@command}"
        content_name = "#{@command}.html"
        layout_method_name = "render_layout"
        layout_name = "layout.html"
      end
      unless respond_to?(layout_method_name)
        erb = ERB.new(@layout)
        erb.def_method(self.class, layout_method_name, layout_name)
      end
      unless respond_to?(content_method_name)
        erb = ERB.new(@template)
        erb.def_method(self.class, content_method_name, content_name)
      end
      __send__(layout_method_name){ __send__(content_method_name) }
    end

    def process(plugin)
      @plugin = plugin
      @body = to_html

      @conf.save_config if @contents[:save_config]
      @headers = {}
      if @contents[:last_modified] and "HEAD" == @request.request_method
        @headers["Last-Modified"]    = CGI.rfc1123_date(@contents[:last_modified])
      end
      @headers["type"]     = "text/html"
      if @conf.mobile_agent?
        @body = NKF.nkf("-sE", @body) if /EUC-JP/i =~ @conf.charset
        @headers["charset"]          = "Shift_JIS"
      else
        @headers["charset"]          = @conf.charset
        @headers["Content-Language"] = @conf.lang
        @headers["Pragma"]           = "no-cache"
        @headers["Cache-Control"]    = "no-cache"
      end
      @headers["Vary"]             = "User-Agent,Accept-Language"
      @headers["Content-Length"]   = @body.bytesize.to_s rescue @body.size.to_s
      @headers["cookie"]           = @plugin.cookies unless @plugin.cookies.empty?
    end

    def out(headers = nil)
      @headers.update(headers) if headers
      response = Hiki::Response.new(@body, 200, @headers)
      if Object.const_defined?(:Rack)
        cookies = @headers.delete("cookie")
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
