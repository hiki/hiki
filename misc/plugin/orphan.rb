# $Id: orphan.rb,v 1.3 2005-06-27 13:49:57 fdiary Exp $
# Copyright (C) 2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

def orphan_pages
  orphan_pgs = []
  references   = []
  name_map   = {}
  
  page_info = @db.page_info

  page_info.each do |p|
    orphan_pgs  << p.keys[0]
    refer      =  p[p.keys[0]][:references]
    references << refer.split(',') if refer.size > 0
    name_map[p.keys[0]] = (p[p.keys[0]][:title] and p[p.keys[0]][:title].size > 0) ? p[p.keys[0]][:title] : p.keys[0]
  end
  orphan_pgs -= references.flatten

  orphan_pgs.sort do |a, b|
    name_map[a] <=> name_map[b]
  end
end

def orphan
  s = '<ul>'

  orphan_pages.each do |p|
    s << %Q!<li>#{hiki_anchor(p.escape, "#{page_name(p)}")}\n!
  end

  s << "</ul>\n"
end

export_plugin_methods(:orphan)
