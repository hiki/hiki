# $Id: google-sitemaps.rb,v 1.1 2005-06-09 13:17:40 yanagita Exp $
# Copyright (C) 2003-2004 TAKEUCHI Hitoshi <hitoshi@namaraii.com>
# Copyright (C) 2005 Kazuhiko <kazuhiko@fdiary.net>
# Copyright (C) 2005 Kouhei Yanagita <sugi@dream.big.or.jp>

def google_sitemaps_body
  sitemaps = %Q!<?xml version="1.0" encoding="UTF-8"?>\n!
  sitemaps << %Q!<urlset xmlns="http://www.google.com/schemas/sitemap/0.84">\n!
  site_last_modified = nil
  @db.page_info.each do |page|
    name = page.keys[0]
    lastmod = page.values[0][:last_modified]
    if site_last_modified.nil? or site_last_modified < lastmod
      site_last_modified = lastmod
    end
    sitemaps << <<_E
  <url>
    <loc>#{@conf.index_url}?#{name.escape}</loc>
    <lastmod>#{lastmod.utc.strftime('%Y-%m-%dT%H:%M:%S+00:00')}</lastmod>
  </url>
_E
  end

  sitemaps << '</urlset>'
  [sitemaps, site_last_modified]
end

def google_sitemaps
  body, last_modified = google_sitemaps_body
  header = Hash::new
  header['Last-Modified'] = CGI::rfc1123_date(last_modified)
  header['type']          = 'text/xml'
  header['charset']       =  'UTF-8'
  header['Content-Language'] = @conf.lang
  header['Pragma']           = 'no-cache'
  header['Cache-Control']    = 'no-cache'
  print @cgi.header(header)
  puts body

  nil # Don't move to the 'FrontPage'
end

add_body_enter_proc(Proc.new do
  add_plugin_command('google_sitemaps', nil)
end)
