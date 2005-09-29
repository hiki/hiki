#!/usr/bin/ruby -Ke
# $Id: hikilet.rb,v 1.1 2005-09-29 05:08:59 fdiary Exp $
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
    end

    def request_method
      @req.request_method
    end

    def header(headers)
      headers.each do |k, v|
        @res[k] = v
      end
      '' # print nothing
    end

    def convert_webrick_hash_to_cgi_hash(webrick_hash)
      cgi_hash = Hash.new([])
      webrick_hash.each do |k,v|
        cgi_hash[k] = [v]
      end
      cgi_hash
    end

    def params
      convert_webrick_hash_to_cgi_hash(@req.query)
    end

    def cookies
      convert_webrick_hash_to_cgi_hash(@req.cookies)
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
  logger = WEBrick::Log::new(STDERR, WEBrick::Log::INFO)

  server = WEBrick::HTTPServer.new(:Port => 12380,
                                   :Logger => logger)

  if FileTest::symlink?( __FILE__ )
    org_path = File::dirname( File::expand_path( File::readlink( __FILE__ ) ) )
  else
    org_path = File::dirname( File::expand_path( __FILE__ ) )
  end
  $:.unshift( org_path.untaint, "#{org_path.untaint}/hiki" )
  $:.delete(".") if File.writable?(".")

  require 'hiki/config'
  conf = Hiki::Config::new

  server.mount("/", Hikilet, conf)
  server.mount("/theme", WEBrick::HTTPServlet::FileHandler, './theme')

  trap("INT") {server.shutdown}
  server.start
end
