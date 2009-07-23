# $Id: referer.rb,v 1.13 2006-07-21 07:36:37 znz Exp $
# Copyright (C) 2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

require 'hiki/db/ptstore'

def add_referer(db)
  begin
    raise unless @db.exist?(@page)
    omit_url = false
    
    if @options['referer.omit_url'] && @cgi.referer
      omit_url = Regexp.new("(#{@options['referer.omit_url'].join('|')})") =~ @cgi.referer
    end
      
    raise if 'HEAD' == @cgi.request_method || ! @cgi.referer ||
                       /^https?/ !~ @cgi.referer || omit_url

    db.transaction do
      db[@cgi.referer] = (db.root?(@cgi.referer) ? db[@cgi.referer] : 0) + 1
    end
  rescue Exception
  end
end

def referers(db)
  db.transaction(true) do
    db.roots.collect do |p|
      [p, db[p]]
    end.sort do |a,b|
      b[1] <=> a[1]
    end
  end
end

def show_short_referer(db)
  s = %Q!<div class="referer">#{referer_short_label} |!
  
  referers(db).each_with_index do |ref, i|
    break if i == @options['referer_limit']
    disp = replace_url(ref[0].unescape).escapeHTML
    s << make_anchor("#{ref[0].escapeHTML}", " #{ref[1]}").gsub(/<a\s+([^>]+)>/i) { %Q!<a #{$1} title="#{disp}">! }
    s << ' |'
  end
  
  s << '</div>'
end

def show_referer(db)
  s = %Q!<div class="referer">#{referer_long_label}<ul>!
  
  referers(db).each_with_index do |ref, i|
    break if i == @options['referer_limit']
    disp = replace_url(ref[0].unescape).escapeHTML
    s << %!<li>#{ref[1]} ! + make_anchor("#{ref[0].escapeHTML}", "#{disp}") + "</li>"
  end
  
  s << '</ul></div>'
end

def referer_path
 "#{@cache_path}/referer"
end

def referer_map
  path = referer_path
  s = ''
  return s unless File.exist?(path)

  s << "<ul>\n"

  Dir.entries(path).sort {|a, b| a.unescape <=> b.unescape}.each do |f|
    next if /(?:^\.)|(?:~$)/ =~ f
    next unless @db.exist?(f.untaint.unescape)
    db = PTStore::new("#{path}/#{f}")
    p = File.basename(f)
    s << "<li>#{hiki_anchor(p, page_name(p.unescape))}</li>\n"
    s << "<ul>\n"
    referers(db).each_with_index do |ref, i|
      break if i == @options['referer_limit']
      disp = replace_url(ref[0].unescape).escapeHTML
      s << %!<li>#{ref[1]} ! + make_anchor("#{ref[0].escapeHTML}", "#{disp}")+"</li>"
    end
    db.close_cache
    s << "</ul>\n"
  end
  
  s << "</ul>\n"
end

def replace_url(url)
  replace_list = @options['referer.replace_url']
  return url unless replace_list
  
  replaced_url = url
  replace_list.each do |list|
    rep_url, rep_str = list.split(' ')
    replaced_url = url.sub(Regexp.new(rep_url), rep_str)
    break if url != replaced_url
  end
  replaced_url
end

add_body_leave_proc(Proc.new do
  begin
    Dir.mkdir(referer_path) unless File.exist?(referer_path)

    file_name = "#{referer_path}/#{@page.escape.to_euc}"
    db = PTStore::new(file_name)
    add_referer(db)
    
    case @options['referer.display_type']
    when 'none'
    when 'long'
      show_referer(db)
    else
      show_short_referer(db)
    end
  rescue Exception
  ensure
    db.close_cache if db 
  end
end)

export_plugin_methods(:referer_map)
