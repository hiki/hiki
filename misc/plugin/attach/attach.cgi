#!/usr/bin/env ruby
# $Id: attach.cgi,v 1.9 2004-09-22 15:02:21 fdiary Exp $
# Copyright (C) 2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

BEGIN { $defout.binmode }

$SAFE     = 1

require 'cgi'
require 'nkf'

if FileTest::symlink?( __FILE__ ) then
  org_path = File::dirname( File::readlink( __FILE__ ) )
else
  org_path = File::dirname( __FILE__ )
end
$:.unshift( org_path.untaint )

require 'hiki/config'
require 'hiki/util'

include Hiki::Util

def attach_file
  @conf = Hiki::Config::new
  set_conf(@conf)
  cgi = CGI.new

  params     = cgi.params
  page       = params['p'][0] ? params['p'][0].read : 'FrontPage'
  command = params['command'][0] ? params['command'][0].read : 'view'
  command = 'view' unless ['view', 'edit'].index(command)
  r = ''

  if cgi.params['attach'][0] then
    raise unless params['p'][0] && params['attach_file'][0]

    filename   = File.basename(params['attach_file'][0].original_filename.gsub(/\\/, '/'))
    cache_path = "#{@conf.cache_path}/attach"

    begin
      Dir.mkdir(cache_path) unless test(?e, cache_path.untaint)
      attach_path = "#{cache_path}/#{page.escape}"
      Dir.mkdir(attach_path) unless test(?e, attach_path)
      path = "#{attach_path}/#{CGI.escape(NKF.nkf('-e', filename))}"
      open(path.untaint, "wb") do |f|
        f.print params['attach_file'][0].read
      end
      r << "FILE        = #{path}\n"
      r << "SIZE        = #{File.size(path)} bytes\n"
    rescue Exception
      r << "#$! (#{$!.class})\n"
      r << $@.join( "\n" )
    ensure
      send_updating_mail(page, 'attach', r) if @conf.mail_on_update
      redirect(cgi, "#{@conf.index_url}?c=#{command}&p=#{page.escape}")
    end
  elsif cgi.params['detach'][0] then
    attach_path = "#{@conf.cache_path}/attach/#{page.escape}"

    begin
      Dir.foreach(attach_path) do |file|
        next unless params["file_#{file}"][0]
        path = "#{attach_path}/#{file}"
        if FileTest::file?(path) and params["file_#{file}"][0].read
          File::unlink(path)
          r << "FILE        = #{path}\n"
        end
      end
      Dir::rmdir(attach_path) if 2 == Dir::entries(attach_path)
    rescue Exception
      r << "#$! (#{$!.class})\n"
      r << $@.join( "\n" )
    ensure
      send_updating_mail(page, 'detach', r) if @conf.mail_on_update
      redirect(cgi, "#{@conf.index_url}?c=#{command}&p=#{page.escape}")
    end
  end
end

def redirect(cgi, url)
  head = {'type' => 'text/html',
         }
   print cgi.header(head)
   print %Q[
            <html>
            <head>
            <meta http-equiv="refresh" content="0;url=#{url}">
            <title>moving...</title>
            </head>
            <body>Wait or <a href="#{url}">Click here!</a></body>
            </html>]
end

attach_file
