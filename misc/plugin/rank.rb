# $Id: rank.rb,v 1.3 2003-02-22 13:04:21 hitoshi Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

def rank( n = 20 )
  n = n > 0 ? n : 0
  
  l = @db.page_info.sort do |a, b|
    b[b.keys[0]][:count] <=> a[a.keys[0]][:count]
  end

  s = "<ul>\n"
  c = 1
  
  l.each do |a|
    break if c > n
    name = a.keys[0]
    p = a[name]
    
    t = "#{name.escapeHTML} (#{p[:count]})"
    an = "<a href=\"#{$cgi_name }?#{name.escape}\" title=\"#{name.escapeHTML}\">#{t}</a>"
    s << "<li>#{an}\n"
    c = c + 1
  end
  s << "</ul>\n"
  s
end