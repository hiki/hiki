# $Id: orphan.rb,v 1.5 2005-09-30 11:45:49 fdiary Exp $
# Copyright (C) 2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

def orphan_pages
  pages = @db.pages.select{|p| @db.get_references(p).empty?}
  pages.collect!{|p| [p, page_name(p)]}
  pages.sort_by{|i| i[1].unescapeHTML}
end

def orphan
  s = '<ul>'

  orphan_pages.each do |p, page_name|
    s << %Q!<li>#{hiki_anchor(p.escape, page_name)}</li>\n!
  end

  s << "</ul>\n"
end

export_plugin_methods(:orphan)
