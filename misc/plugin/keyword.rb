# $Id: keyword.rb,v 1.2 2004-02-15 02:48:35 hitoshi Exp $
# Copyright (C) 2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

def keyword_list(*key)
  # sort by category
  list = keywords(*key).to_a.sort {|a,b| a[0].downcase <=> b[0].downcase}
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
      s << "<li>#{format_date( tm )}: #{hiki_anchor(name.escape, page_name(name))}\n"
    end
    s << "</ul>\n"
  end
  s
end

def keywords(*keyword)
  keyword.collect! {|a| a.unescapeHTML}

  key = Hash::new
  @db.page_info.each do |info|
    next unless info.values[0][:keyword]
    info.values[0][:keyword].each do |k|
      if keyword.size == 0 || keyword.index(k)
        key[k] = [] unless key[k]
        key[k] << info
      end
    end
  end
  key
end
