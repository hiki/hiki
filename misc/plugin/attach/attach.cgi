#!/usr/bin/env ruby

# $Id: attach.cgi,v 1.2 2004-02-15 02:48:35 hitoshi Exp $
# Copyright (C) 2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

require 'cgi'
require 'nkf'

def attach_image
  cgi = CGI.new

  if cgi.params['attach'][0] then
    params     = cgi.params
    page       = CGI.escape(params['p'][0] ? params['p'][0].read : 'FrontPage')
    raise unless params['p'][0] && params['attach_file'][0]

    command = params['command'][0] ? params['command'][0].read : 'view'
    command = 'view' unless ['view', 'edit'].index(command)

    filename   = File.basename(params['attach_file'][0].original_filename.gsub(/\\/, '/'))
    cache_path = "#{params['cache_path'][0].read}/attach"

    begin
      Dir.mkdir(cache_path) unless test(?e, cache_path)
      attach_path = "#{cache_path}/#{page}"
      Dir.mkdir(attach_path) unless test(?e, attach_path)

      open("#{attach_path}/#{CGI.escape(NKF.nkf('-e', filename))}",  "wb") do |f|
        f.print params['attach_file'][0].read
      end
    rescue Exception
    ensure
      if params['refresh'][0] then 
        url=params['refresh'][0].read
      else
        url=$cgi_name
      end
      redirect(cgi, "#{url}?c=#{command}&p=#{page}")
    end
  elsif cgi.params['detach'][0] then
    params     = cgi.params
    page       = CGI.escape(params['p'][0] ? params['p'][0].read : 'FrontPage')

    command = params['command'][0] ? params['command'][0].read : 'view'
    command = 'view' unless ['view', 'edit'].index(command)

    attach_path = "#{params['cache_path'][0].read}/attach/#{page}"

    begin
      Dir.foreach(attach_path) do |file|
        next unless params["file_#{file}"][0]
        if FileTest::file?("#{attach_path}/#{file}") and params["file_#{file}"][0].read
          File::unlink("#{attach_path}/#{file}")
        end
      end
      Dir::rmdir(attach_path) if 2 == Dir::entries(attach_path)
    rescue Exception
    ensure
      if params['refresh'][0] then 
        url=params['refresh'][0].read
      else
        url=$cgi_name
      end
      redirect(cgi, "#{url}?c=#{command}&p=#{page}")
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

attach_image
