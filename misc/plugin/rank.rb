# $Id: rank.rb,v 1.4 2004-02-15 02:48:35 hitoshi Exp $
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
    
    t = "#{page_name(name)} (#{p[:count]})"
    an = hiki_anchor( name.escape, t )
    s << "<li>#{an}\n"
    c = c + 1
  end
  s << "</ul>\n"
  s
end
