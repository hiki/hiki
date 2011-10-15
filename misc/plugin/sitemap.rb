# $Id: sitemap.rb,v 1.5 2005-09-30 11:45:49 fdiary Exp $
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

  @map_str << "<li>#{hiki_anchor(page.escape, "#{page_name(page)}")}</li>\n"

  unless @map_traversed.index(page)
    referer =  info[:references].sort
    if referer.size > 0
      @map_str << "<ul>\n"
      referer.each do |r|
        sitemap_traverse(r)
      end
      @map_str << "</ul>\n"
    end
    @map_traversed << page
  end
  @map_path.pop
end

export_plugin_methods(:sitemap)
