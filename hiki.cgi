#!/usr/bin/env ruby
# $Id: hiki.cgi,v 1.19 2004-06-26 14:12:27 fdiary Exp $
# Copyright (C) 2002-2004 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

BEGIN { $defout.binmode }

$SAFE     = 1
$KCODE    = 'e'

begin
  if FileTest::symlink?( __FILE__ ) then
    org_path = File::dirname( File::readlink( __FILE__ ) )
  else
    org_path = File::dirname( __FILE__ )
  end
  $:.unshift( org_path.untaint )
  require 'cgi'

  require 'hiki/config'
  conf = Hiki::Config::new
  require "style/#{conf.style}/html_formatter"
  require "style/#{conf.style}/parser"
  require "messages/#{conf.lang}"
  require "hiki/db/#{conf.database_type}"

  require 'hiki/command'
  cgi = CGI::new
  db = Hiki::HikiDB::new( conf )
  db.open_db {
    cmd = Hiki::Command::new( cgi, db, conf )
    cmd.dispatch
  }
rescue Exception
  if cgi then
    print cgi.header( 'type' => 'text/plain' )
  else
    print "Content-Type: text/plain\n\n"
  end
  puts "#$! (#{$!.class})\n"
  puts $@.join( "\n" )
end
