# $Id: recent2.rb,v 1.3 2004-12-14 16:12:33 fdiary Exp $
# Copyright (C) 2003 not <not@cds.ne.jp>

def recent2( n = 20 )
  n = n > 0 ? n : 0

  now = Time::now
  
  l = @db.page_info.sort do |a, b|
    b[b.keys[0]][:last_modified] <=> a[a.keys[0]][:last_modified]
  end

  s = "<ul>\n"

  l[0..n-1].each do |a|

    name = a.keys[0]
    p = a[name]
    
    tm = p[:last_modified ] 

    tp = now - tm
    if tp < 3600 then
      ps = "#{(tp / 60).to_i}m"
    elsif tp < 86400 then
      ps = "#{(tp / 3600).to_i}h"
    else
      ps = "#{(tp / 86400).to_i}d"
    end

    cur_date = tm.strftime( @conf.msg_date_format )
    t = page_name(name)
    an = hiki_anchor(name.escape, t)
    s << "<li title=\"#{cur_date}\">#{an} <span class=\"recent2\">(#{ps})</span>\n"
  end
  s << "</ul>\n"
  s
end
