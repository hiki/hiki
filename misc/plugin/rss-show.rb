# $Id: rss-show.rb,v 1.11 2005-09-26 13:35:05 fdiary Exp $
# Copyright (C) 2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

require 'rss/1.0'
require 'rss/2.0'

def rss_show(url, cache_time = 1800, number = 5)
  if rss = rss_get(url.untaint, cache_time)
    items = RSS::Parser.parse(rss, false).items
    rss_format_items(items[0...number])
  else
    ''
  end
end

def rss_get(url, cache_time)
  Dir.mkdir("#{@cache_path}/rss-show") unless File.exist?("#{@cache_path}/rss-show")
  cache_file = "#{@cache_path}/rss-show/#{url.escape}".untaint

  begin
    rss_recent_cache(url, cache_file, cache_time)
    raise unless File.readable?(cache_file)
    open(cache_file).read
  rescue Exception
    nil
  end
end

def rss_recent_cache(url, cache_file, cache_time)
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

      if /^([^:]+):(\d+)$/ =~ @options['rss.proxy'] then
        proxy_host = $1
        proxy_port = $2.to_i
      end

      if url =~ /(https?:\/\/)(.+?)(\/.*)/
        host = $2
        path = $3
      end
      Net::HTTP.Proxy( proxy_host, proxy_port ).start( host, port ) do |http|
        response , = http.get(path)
        rss_write_cache(cache_file, response.body)
      end
    rescue
      nil
    end
  end
end

def rss_format_items(items)
  html = "<ul>\n"
  items.each do |i|
    page = utf8_to_euc( i.title )
    url = utf8_to_euc( i.link )
    html << "<li>#{make_anchor(url.escapeHTML, page.unescapeHTML.escapeHTML)}</li>\n"
  end
  html << "</ul>\n"
end
 
def rss_write_cache(cache_file, rss)
  File.open(cache_file, 'w') do |f|
    f.flock(File::LOCK_EX)
    f.puts rss
    f.flock(File::LOCK_UN)
  end
end

export_plugin_methods(:rss_show)
