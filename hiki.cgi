#!/usr/bin/env ruby
# $Id: hiki.cgi,v 1.8 2003-03-23 03:26:30 hitoshi Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

$SAFE     = 1
$KCODE    = 'e'

HIKI_VERSION  = '0.42'

require 'cgi'
require 'hikiconf'
require 'hiki/global'
require 'hiki/command'
require 'hiki/util'
require "hiki/db/#{$database_type}"
include Hiki::Util

begin
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
