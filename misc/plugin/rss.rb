# $Id: rss.rb,v 1.10 2005-01-05 01:05:48 fdiary Exp $
# Copyright (C) 2003-2004 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

def rss_recent_label
  '更新日時順'
end

def rss_body(page_num = 10)

  pages = @db.page_info.sort do |a, b|
    k1 = a.keys[0]
    k2 = b.keys[0]
    b[k2][:last_modified] <=> a[k1][:last_modified]
  end

  n = 0
  item_list = ''
  last_modified = pages[0].values[0][:last_modified]

  items = <<EOS
<?xml version="1.0" encoding="#{@conf.charset}" standalone="yes"?>
<rdf:RDF xmlns="http://purl.org/rss/1.0/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:content="http://purl.org/rss/1.0/modules/content/" xml:lang="ja-JP">
  <channel rdf:about="#{@conf.index_url}?c=recent">
    <title>#{CGI::escapeHTML(@conf.site_name)} : #{rss_recent_label}</title>
    <link>#{@conf.index_url}?c=recent</link>
    <description>#{CGI::escapeHTML(@conf.site_name)} #{rss_recent_label}</description>
    <language>ja</language>
    <copyright>Copyright (C) #{CGI::escapeHTML(@conf.author_name)}</copyright>
    <dc:date>#{last_modified.utc.strftime("%Y-%m-%dT%H:%M:%S+00:00")}</dc:date>
    <items>
      <rdf:Seq>
EOS

  pages.each do |p|
    break if (n += 1) > page_num
    name = p.keys[0]
    src = @db.load_backup(name) || ''
    dst = @db.load(name) || ''
    content = unified_diff(src, dst)
    
    items << '        '

    uri = "#{@conf.index_url}?#{name.escape}"
    items << %Q!<rdf:li resource="#{uri}"/>\n!

    item_list << <<EOS
  <item rdf:about="#{uri}">
    <title>#{CGI::escapeHTML(page_name(name))}</title>
    <link>#{uri}</link>
    <dc:date>#{p[name][:last_modified].utc.strftime("%Y-%m-%dT%H:%M:%S+00:00")}</dc:date>
    <content:encoded><![CDATA[<pre>\n#{CGI::escapeHTML(content)}</pre>]]></content:encoded>
  </item>
EOS
  end

  items << <<EOS
      </rdf:Seq>
    </items>
  </channel>
EOS

  items << item_list << '</rdf:RDF>'
  return( [items, last_modified] )
end

def rss
  body, last_modified = rss_body
  header = Hash::new
  header['Last-Modified'] = CGI::rfc1123_date(last_modified)
  header['type']          = 'text/xml'
  header['charset']       =  @conf.charset
  header['Content-Language'] = @conf.lang
  header['Pragma']           = 'no-cache'
  header['Cache-Control']    = 'no-cache'
  print @cgi.header(header)
  puts body

  nil # Don't move to the 'FrontPage'
end
add_body_enter_proc(Proc.new do
  add_plugin_command('rss', 'RSS')
end)
add_header_proc(Proc.new do
  %Q!  <link rel="alternate" type="application/rss+xml" title="RSS" href="#{@conf.index_url}?c=rss">!
end)
