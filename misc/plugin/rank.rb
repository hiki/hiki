# $Id: rank.rb,v 1.1.1.1 2003-02-22 04:39:31 hitoshi Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>
# You can redistribute it and/or modify it under the terms of
# the Ruby's licence.#

def rank( n = 20 )
  n = n > 0 ? n : 0
  
  l = @db.page_info.sort do |a, b|
    b[b.keys[0]][:count] <=> a[a.keys[0]][:count]
  end

  s = '<ul>'
  c = 1
  
  l.each do |a|
    break if c > n
    name = a.keys[0]
    p = a[name]
    
    t = "#{name.escapeHTML} (#{p[:count]})"
    an = "<a href=\"#{$cgi_name }?#{name.escape}\" title=\"#{name.escapeHTML}\">#{t}</a>"
    s << "<li>#{an}</li>"
    c = c + 1
  end
  s << '</ul>'
  s
end