# $Id: rss.rb,v 1.23 2008-07-06 02:40:43 hsbt Exp $
# Copyright (C) 2003-2004 TAKEUCHI Hitoshi <hitoshi@namaraii.com>
# Copyright (C) 2005 Kazuhiko <kazuhiko@fdiary.net>

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
  <channel rdf:about="#{@conf.index_url}?c=rss">
    <title>#{CGI::escapeHTML(@conf.site_name)} : #{label_rss_recent}</title>
    <link>#{@conf.index_url}?c=recent</link>
    <description>#{CGI::escapeHTML(@conf.site_name)} #{label_rss_recent}</description>
    <dc:language>ja</dc:language>
    <dc:rights>Copyright (C) #{CGI::escapeHTML(@conf.author_name)}</dc:rights>
    <dc:date>#{last_modified.utc.strftime('%Y-%m-%dT%H:%M:%S+00:00')}</dc:date>
    <items>
      <rdf:Seq>
EOS
  pages.each do |p|
    break if (n += 1) > page_num
    name = p.keys[0]
    src = @db.load_backup(name) || ''
    dst = @db.load(name) || ''

    case @conf['rss.mode']
    when 1
      content = word_diff(src, dst, true).strip.gsub(/\n/, "<br>\n")
    when 2
      content = word_diff(src, dst).strip.gsub(/\n/, "<br>\n")
    when 3
      tokens = @db.load_cache( name )
      unless tokens
        parser = @conf.parser::new( @conf )
        tokens = parser.parse( @db.load( name ) )
        @db.save_cache( name, tokens )
      end
      tmp = @conf.use_plugin
      @conf.use_plugin = false
      formatter = @conf.formatter::new( tokens, @db, Plugin.new( @conf.options, @conf), @conf )
      content = formatter.to_s
      @conf.use_plugin = tmp
    else
      content = CGI::escapeHTML(unified_diff(src, dst)).strip.gsub(/\n/, "<br>\n").gsub(/ /, '&nbsp;')
    end

    if content and content.empty?
      content = shorten(dst).strip.gsub(/\n/, "<br>\n")
    end
    
    items << '        '

    uri = "#{@conf.index_url}?#{name.escape}"
    items << %Q!<rdf:li rdf:resource="#{uri}"/>\n!

    item_list << <<EOS
  <item rdf:about="#{uri}">
    <title>#{CGI::escapeHTML(page_name(name))}</title>
    <link>#{uri}</link>
    <dc:date>#{p[name][:last_modified].utc.strftime('%Y-%m-%dT%H:%M:%S+00:00')}</dc:date>
EOS
    item_list << "    <content:encoded><![CDATA[<div>#{content}</div>]]></content:encoded>" if content
    item_list << '  </item>'
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

  require 'time'
  begin
    if_modified_since = Time.parse(ENV['HTTP_IF_MODIFIED_SINCE'])
  rescue
    if_modified_since = nil
  end

  if if_modified_since and last_modified < if_modified_since
    header['status'] = 'NOT_MODIFIED'
    print @cgi.header(header)
  else
    header['Last-Modified'] = CGI::rfc1123_date(last_modified)
    header['type']          = 'text/xml'
    header['charset']       =  @conf.charset
    header['Content-Language'] = @conf.lang
    header['Pragma']           = 'no-cache'
    header['Cache-Control']    = 'no-cache'
    print @cgi.header(header)
    puts body
  end

  nil # Don't move to the 'FrontPage'
end

add_body_enter_proc(Proc.new do
  @conf['rss.mode'] ||= 0
  if @conf['rss.menu'] == 1
    add_plugin_command('rss', nil)
  else
    add_plugin_command('rss', 'RSS')
  end
end)

add_header_proc(Proc.new do
  %Q!  <link rel="alternate" type="application/rss+xml" title="RSS" href="#{@conf.index_url}?c=rss">!
end)

def saveconf_rss
  if @mode == 'saveconf' then
    @conf['rss.mode'] = @cgi.params['rss.mode'][0].to_i
  end
end

if @cgi.params['conf'][0] == 'rss' && @mode == 'saveconf'
  @conf['rss.menu'] = @cgi.params['rss.menu'][0].to_i
end

add_conf_proc('rss', label_rss_config) do
  saveconf_rss
  str = <<-HTML
  <h3 class="subtitle">#{label_rss_mode_title}</h3>
  <p><select name="rss.mode">
  HTML
  label_rss_mode_candidate.each_index{ |i|
    str << %Q|<option value="#{i}"#{@conf['rss.mode'] == i ? ' selected' : ''}>#{label_rss_mode_candidate[i]}</option>\n|
  }
  str << "</select></p>\n"
  str << <<-HTML
  <h3 class="subtitle">#{label_rss_menu_title}</h3>
  <p><select name="rss.menu">
  HTML
  label_rss_menu_candidate.each_index{ |i|
    str << %Q|<option value="#{i}"#{@conf['rss.menu'] == i ? ' selected' : ''}>#{label_rss_menu_candidate[i]}</option>\n|
  }
  str << "</select></p>\n"
  str
end

export_plugin_methods(:rss)
