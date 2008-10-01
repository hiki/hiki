#!/usr/bin/ruby -Ke
# $Id: hikilet.rb,v 1.12 2008-01-06 05:49:30 znz Exp $
# Copyright (C) 2005-2007 Kazuhiro NISHIYAMA

require 'hiki/config'
require 'thread'
require 'webrick/httpservlet/abstract'

class Hikilet < WEBrick::HTTPServlet::AbstractServlet
  DEFOUT = Object.new
  def DEFOUT.write(s)
    (Thread.current[:defout]||::STDOUT) << s.to_s
  end
  $stdout = DEFOUT

  class DummyCGI
    def initialize(req=nil, res=nil)
      @req, @res = req, res
      @params = nil
      @cookies = nil
    end

    def request_method
      @req.request_method
    end

    def header(headers)
      headers.each do |k, v|
        case k
        when 'cookie'
          @res['Set-Cookie'] = v
        when 'type'
          @res['Content-Type'] = v
        else
          @res[k] = v
        end
      end
      '' # print nothing
    end

    def params
      return @params if @params
      @params = Hash.new([])
      if @req
        @req.query.each do |k,v|
          @params[k] = [v]
        end
      end
      @params
    end

    def [](key)
      params[key][0]
    end

    def cookies
      return @cookies if @cookies
      @cookies = Hash.new([])
      @req.cookies.each do |cookie|
        @cookies[cookie.name] = [cookie.value]
      end
      @cookies
    end
  end

  Mutex_of_HTTP_ACCEPT_LANGUAGE = Mutex.new

  def do_GET(req, res)
    proc do
      begin
        $SAFE = 1
        Thread.current[:defout] = ''

        # ugly hack
        # can not use Thread.exclusive because Thread.start in load_cgi_conf
        conf = nil
        Mutex_of_HTTP_ACCEPT_LANGUAGE.synchronize do
          saved_HTTP_ACCEPT_LANGUAGE = ENV['HTTP_ACCEPT_LANGUAGE']
          ENV['HTTP_ACCEPT_LANGUAGE'] = req['Accept-Language']
          conf = Hiki::Config::new
          ENV['HTTP_ACCEPT_LANGUAGE'] = saved_HTTP_ACCEPT_LANGUAGE
        end

        cgi = DummyCGI::new(req, res)
        db = conf.database
        db.open_db do
          cmd = Hiki::Command::new( cgi, db, conf )
          cmd.dispatch
        end

        res.body, Thread.current[:defout] = Thread.current[:defout], nil
        if res['location']
          res.status = 302
        end
      rescue Exception => err
        res.status = 500
        res['content-type'] = 'text/html'
        res.body = [
          '<html><head><title>Hiki Error</title></head><body>',
          '<h1>Hiki Error</h1>',
          '<pre>',
          CGI.escapeHTML( "#{err} (#{err.class})\n" ),
          CGI.escapeHTML( err.backtrace.join( "\n" ) ),
          '</pre>',
          "<div>#{' ' * 500}</div>",
          '</body></html>',
        ].join('')
      end
    end.call
  end

  def do_HEAD(req, res)
      do_GET(req, res)
  end

  def do_POST(req, res)
    do_GET(req, res)
  end
end

if __FILE__ == $0
  require 'webrick'
  require 'logger'

  # load conf
  conf = Hiki::Config::new
  base_url = URI.parse(conf.base_url)
  unless base_url.is_a?(URI::HTTP)
    raise "@base_url must be full http URL (e.g. http://localhost:10080/ ): current base_url=#{conf.base_url.inspect}"
  end
  theme_url = base_url + conf.theme_url
  theme_path = conf.theme_path
  xmlrpc_enabled = conf.xmlrpc_enabled
  # release conf (need to load conf each request because content-negotiation)
  conf = nil

  # CGI environments emulation
  ENV['SERVER_NAME'] ||= base_url.host
  ENV['SERVER_PORT'] ||= base_url.port.to_s
  logger = WEBrick::Log::new(STDERR, WEBrick::Log::INFO)
  server = WEBrick::HTTPServer.new({
    :Port => base_url.port,
    :Logger => logger,
  })

  # prepare $LOAD_PATH
  if FileTest::symlink?( __FILE__ )
    org_path = File::dirname( File::expand_path( File::readlink( __FILE__ ) ) )
  else
    org_path = File::dirname( File::expand_path( __FILE__ ) )
  end
  $:.unshift( org_path.untaint, "#{org_path.untaint}/hiki" )
  $:.delete(".") if File.writable?(".")

  # mount hiki
  if false # use hiki.cgi instead of Hikilet (for debug)
    server.mount(base_url.path, WEBrick::HTTPServlet::CGIHandler, 'hiki.cgi')
  else
    server.mount(base_url.path, Hikilet)
  end

  # mount theme
  if base_url.host == theme_url.host && base_url.port == theme_url.port
    server.mount(theme_url.path, WEBrick::HTTPServlet::FileHandler, theme_path)
  end

  # mount attach.cgi
  if File.exist?('attach.cgi')
    server.mount(base_url.path + 'attach.cgi', WEBrick::HTTPServlet::CGIHandler, 'attach.cgi')
  end

  if xmlrpc_enabled
    require 'hiki/xmlrpc'
    xmlrpc_servlet = XMLRPC::WEBrickServlet.new
    ::Hiki::XMLRPCHandler.init_handler(xmlrpc_servlet, ::Hikilet::DummyCGI)
    server.mount('/HikiRPC', xmlrpc_servlet)
  end

  trap("INT") {server.shutdown}
  server.start
end
