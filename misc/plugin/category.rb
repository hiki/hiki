# $Id: category.rb,v 1.6 2005-09-30 11:45:49 fdiary Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

def category_list(*category)
  category_re = /^\(([^\)]+?)\)/

  category.collect! {|a| a.unescapeHTML}
  
  l = Hash::new
  @db.page_info.each do |a|
    if category_re =~ a.keys[0] && (category.size == 0 || category.index($1))
      l[$1] = [] unless l[$1]
      l[$1] << a
    end
  end

  # sort by category
  list = l.to_a.sort {|a,b| a[0] <=> b[0]}
  s = ''

  list.each do |j|
    category = j[0]
    p = j[1]
    s << "<h2>#{view_title(category)}</h2>\n"
    s << "<ul>\n"
    # sort by page name
    p.collect! { |i| i.to_a.flatten! }.sort! do |p1, p2|
      p2[1][:last_modified] <=> p1[1][:last_modified]
    end
    
    p.each do |a|
      name = a[0]
      tm = a[1][:last_modified]
      s << "<li>#{format_date( tm )}: #{hiki_anchor(name.escape, page_name(name))}</li>\n"
    end
    s << "</ul>\n"
  end
  s
end
