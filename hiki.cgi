#!/usr/bin/env ruby
# $Id: hiki.cgi,v 1.15 2004-03-11 02:31:23 hitoshi Exp $
# Copyright (C) 2002-2004 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

BEGIN { $defout.binmode }

$SAFE     = 1
$KCODE    = 'e'

$path  = File::dirname(__FILE__)

HIKI_VERSION  = '0.7-devel-20040310'

begin
  require 'cgi'
  require './hikiconf'
  require 'hiki/global'
  require 'hiki/command'
  require 'hiki/util'
  require "hiki/db/#{$database_type}"
  include Hiki::Util

  load_config

  cgi = CGI::new
  db = Hiki::HikiDB::new
  db.open_db {
    cmd = Hiki::Command::new( cgi, db )
    cmd.dispatch
  }
rescue Exception
  print "Content-Type: text/plain\n\n"
  puts "#$! (#{$!.class})\n\n"
  puts $@.join( "\n" )
end
