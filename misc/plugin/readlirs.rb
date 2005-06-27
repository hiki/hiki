# $Id: readlirs.rb,v 1.6 2005-06-27 07:38:08 fdiary Exp $
# Copyright (C) 2003 yoshimi <yoshimik@iris.dti.ne.jp>

require 'cgi'

def readlirs( url, n = 20,  style=1, cache_time = 1800, tf="%Y/%m/%d %H:%m" )
  n = 20 unless n.respond_to?(:integer?)
  n = n > 0 ? n : 200
  style = 1 unless n.respond_to?(:integer?)

  if lirs = readlirs_get(url, cache_time)
    items = readlirs_sort(lirs)
    s = "<ol>\n"
    c = 1
    items.each do |line|
      break if c > n
      data = line.split(/,/)
      case style
      when 1
        an = "#{Time.at(data[1].to_i).strftime(tf)} <a href=\"#{CGI::escapeHTML(data[5])}\" title=\"#{CGI::escapeHTML(data[6])}\">#{CGI::escapeHTML(data[6])}</a> #{CGI::escapeHTML(data[7])}" if style
      when 2
        an = "#{Time.at(data[1].to_i).strftime(tf)}<br><a href=\"#{CGI::escapeHTML(data[5])}\" title=\"#{CGI::escapeHTML(data[6])}\">#{CGI::escapeHTML(data[6])}</a>"
      when 3
        an = "<a href=\"#{CGI::escapeHTML(data[5])}\" title=\"#{Time.at(data[1].to_i).strftime(tf)} - #{CGI::escapeHTML(data[7])}\">#{CGI::escapeHTML(data[6])}</a>"
      else
        an = "#{Time.at(data[1].to_i).strftime(tf)} <a href=\"#{CGI::escapeHTML(data[5])}\" title=\"#{CGI::escapeHTML(data[6])}\">#{CGI::escapeHTML(data[6])}</a> #{CGI::escapeHTML(data[7])}" if style
      end
      s << "<li>#{an}</li>\n"
      c = c + 1
    end
    s << "</ol>\n"
    s
  else
    ''
  end
end

def readlirs_get(url, cache_time)
  if /^(https?:\/\/)(.+?)(\/.*)/ =~ url
    Dir.mkdir("#{@cache_path}/readlirs") unless File.exist?("#{@cache_path}/readlirs")
    cache_file = "#{@cache_path}/readlirs/#{CGI::escape(url)}".untaint
    begin
      readlirs_recent_cache(url, cache_file, cache_time)
      raise unless File.readable?(cache_file)
      open(cache_file).read
    rescue Exception
      nil
    end
  else
    open(url).read
  end
end

def readlirs_recent_cache(url, cache_file, cache_time)
  begin
    raise if Time.now > File.mtime(cache_file) + cache_time
  rescue
    begin
      require 'net/http'
      port = 80
      host = ''
      path = ''
      proxy_host = nil
      proxy_port = nil
                        
      if /^([^:]+):(\d+)$/ =~ @options['readlirs.proxy'] then
        proxy_host = $1
        proxy_port = $2.to_i
      end
                        
      if url =~ /(https?:\/\/)(.+?)(\/.*)/
        host = $2.untaint
        path = $3
      end
      Net::HTTP.Proxy( proxy_host, proxy_port ).start( host, port ) do |http|
        response , = http.get(path)
        readlirs_write_cache(cache_file, response.body)
      end
    rescue
      $stderr.puts $!, $@.join("\n")
      nil
    end
  end
end

def readlirs_write_cache(cache_file, lirs)
  File.open(cache_file, 'w') do |f|
    f.flock(File::LOCK_EX)
    f.puts lirs
    f.flock(File::LOCK_UN)
  end
end

def readlirs_sort(lirs)
  lirs.sort do |a, b|
    b.split(/,/)[1].to_i <=> a.split(/,/)[1].to_i
  end
end

export_plugin_methods(:readlirs)
