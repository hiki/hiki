# $Id: 00default.rb,v 1.1.1.1 2003-02-22 04:39:31 hitoshi Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>
# You can redistribute it and/or modify it under the terms of
# the Ruby's licence.#

def anchor( s )
  s.sub!(/^\d+$/, '')
  p = @page.escape.escapeHTML
  p.gsub!(/%/, '%%')
  %Q[?#{p}##{s}]
end

def my( a, str )
  %Q[<a href="#{anchor(a).gsub!(/%%/, '%')}">#{str.escapeHTML}</a>]
end

#==============================
#  Hiki default plugins
#==============================
def toc
  @toc_f = true
end

def recent( n = 20 )
  n = n > 0 ? n : 0

  l = @db.page_info.sort do |a, b|
    b[b.keys[0]][:last_modified] <=> a[a.keys[0]][:last_modified]
  end

  s = '<ul>'
  c = 1
  d = nil
  
  l.each do |a|
    break if c > n
    name = a.keys[0]
    p = a[name]
    
    tm = p[:last_modified ] 
    cur_date = tm.strftime( msg_date_format )

    if d != cur_date
      s << "<h5>#{cur_date}</h5>"
      d = cur_date
    end
    t = name.escapeHTML
    an = "<a href=\"#{$cgi_name }?#{name.escape}\" title=\"#{name.escapeHTML}\">#{t}</a>"
    s << "<li>#{an}</li>"
    c = c + 1
  end
  s << '</ul>'
  s
end

