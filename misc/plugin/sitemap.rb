# $Id: sitemap.rb,v 1.2 2004-02-15 02:48:35 hitoshi Exp $
# Copyright (C) 2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

def sitemap(page = 'FrontPage')
  @map_path = []
  @map_traversed = []
  @map_str = ''

  return '' unless @db.exist?(page)
  @map_str = "<ul>\n"
  sitemap_traverse(page)
  @map_str << "</ul>\n"
end

def sitemap_traverse(page)
  info = @db.info(page)
  return if @map_path.index(page) or !info
  @map_path.push page

  @map_str << "<li>#{hiki_anchor(page.escape, "#{page_name(page)}")}\n"

  unless @map_traversed.index(page)
    referer =  info[:references]
    if referer.size > 0
      @map_str << "<ul>\n"
      references = referer.size > 0 ? referer.split(',').sort : []
      references.each do |r|
        sitemap_traverse(r)
      end
      @map_str << "</ul>\n"
    end
    @map_traversed << page
  end
  @map_path.pop
end
