#!/usr/bin/ruby -Ke
# $Id: hikilet.rb,v 1.2 2006-09-02 06:40:24 znz Exp $
# Copyright (C) 2005 Kazuhiro NISHIYAMA

require 'webrick/httpservlet/abstract'

def print(s)
  Thread.current[:defout] << s.to_s
end
def puts(s)
  print s.to_s.sub(/\n?\z/, "\n")
end

class Hikilet < WEBrick::HTTPServlet::AbstractServlet
  class CGI
    def initialize(req, res)
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
        else
          @res[k] = v
        end
      end
      '' # print nothing
    end

    def params
      return @params if @params
      @params = Hash.new([])
      @req.query.each do |k,v|
        @params[k] = [v]
      end
      @params
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

  def initialize(server, *options)
    @conf = options.shift
    super(server, *options)
  end

  def do_GET(req, res)
    Thread.current[:defout] = ''
    cgi = CGI::new(req, res)

    db = Hiki::HikiDB::new( @conf )
    db.open_db {
      cmd = Hiki::Command::new( cgi, db, @conf )
      cmd.dispatch
    }
    res.body = Thread.current[:defout]
    if res['location']
      res.status = 302
    end
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
  logger = WEBrick::Log::new(STDERR, WEBrick::Log::INFO)
  port = 12380
  server = WEBrick::HTTPServer.new({
    :Port => port,
    :Logger => logger,
  })

  if FileTest::symlink?( __FILE__ )
    org_path = File::dirname( File::expand_path( File::readlink( __FILE__ ) ) )
  else
    org_path = File::dirname( File::expand_path( __FILE__ ) )
  end
  $:.unshift( org_path.untaint, "#{org_path.untaint}/hiki" )
  $:.delete(".") if File.writable?(".")

  require 'hiki/config'
  conf = Hiki::Config::new
  $hiki_base_url = "http://localhost:#{port}/"
  def conf.base_url
    @base_url || $hiki_base_url
  end

  server.mount("/", Hikilet, conf)
  server.mount("/theme", WEBrick::HTTPServlet::FileHandler, './theme')

  trap("INT") {server.shutdown}
  server.start
end
