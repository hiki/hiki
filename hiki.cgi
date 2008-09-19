#!/usr/bin/env ruby
# $Id: hiki.cgi,v 1.36 2008-01-24 15:42:11 znz Exp $
# Copyright (C) 2002-2004 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

BEGIN { $stdout.binmode }

$KCODE    = 'e'

begin
  if FileTest::symlink?( __FILE__ )
    org_path = File::dirname( File::expand_path( File::readlink( __FILE__ ) ) )
  else
    org_path = File::dirname( File::expand_path( __FILE__ ) )
  end
  $:.unshift( org_path.untaint, "#{org_path.untaint}/hiki" )
  $:.delete(".") if File.writable?(".")

  require 'hiki/config'
  conf = Hiki::Config::new

  if ENV['CONTENT_TYPE'] =~ %r!\Atext/xml!i and ENV['REQUEST_METHOD'] =~ /\APOST\z/i
    require 'hiki/xmlrpc'
    server = Hiki::XMLRPCServer::new( conf.xmlrpc_enabled )
    server.serve
  else
    cgi = CGI::new

    db = conf.database
    db.open_db {
      cmd = Hiki::Command::new( cgi, db, conf )
      cmd.dispatch
    }
  end
rescue Exception => err
  if cgi
    print cgi.header( 'status' => '500 Internal Server Error', 'type' => 'text/html' )
  else
    print "Status: 500 Internal Server Error\n"
    print "Content-Type: text/html\n\n"
  end

  require 'cgi'
  puts '<html><head><title>Hiki Error</title></head><body>'
  puts '<h1>Hiki Error</h1>'
  puts '<pre>'
  puts CGI.escapeHTML( "#{err} (#{err.class})\n" )
  puts CGI.escapeHTML( err.backtrace.join( "\n" ) )
  puts '</pre>'
  puts "<div>#{' ' * 500}</div>"
  puts '</body></html>'
end
