#!/usr/bin/env ruby
# $Id: hiki.cgi,v 1.31 2005-06-14 13:49:07 fdiary Exp $
# Copyright (C) 2002-2004 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

BEGIN { $defout.binmode }

$SAFE     = 1
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

  cgi = CGI::new

  db = Hiki::HikiDB::new( conf )
  db.open_db {
    cmd = Hiki::Command::new( cgi, db, conf )
    cmd.dispatch
  }
rescue Exception => err
  if cgi
    print cgi.header( 'type' => 'text/html' )
  else
    print "Content-Type: text/html\n\n"
  end

  require 'cgi'
  puts '<html><head><title>Hiki Error</title></head><body><pre>'
  puts CGI.escapeHTML( "#{err} (#{err.class})\n" )
  puts CGI.escapeHTML( err.backtrace.join( "\n" ) )
  puts '</pre></body></html>'
end
