# $Id: interwiki.rb,v 1.6 2004-06-26 14:12:28 fdiary Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

module Hiki
  class InterWiki
    require 'hiki/util'
    
    URL  = '(?:http|https|ftp|mailto|file):[a-zA-Z0-9;/?:@&=+$,\-_.!~*\'()#%]+'
    INTERWIKI_NAME_RE =  /\[\[([^|]+)\|(#{URL})\]\](?:\s+(sjis|euc|alias))?/

    attr_reader :interwiki_names
    
    def initialize(db, plugin, conf)
      @db = db
      @conf = conf
      @plugin = plugin
      @interwiki_names = Hash::new
      
      load_interwiki_names
    end

    def interwiki(s, p, display_text = "#{s}:#{p}".escapeHTML)
      if @interwiki_names.has_key?(s)
        encoding = @interwiki_names[s][:encoding]
        page = case encoding
               when 'sjis'
                 p.to_sjis.escape
               when 'euc'
                 p.to_euc.escape
               else
                 p
               end
        if encoding == 'alias'
          @plugin.make_anchor("#{@interwiki_names[s][:url]}", s.escapeHTML)
        elsif @interwiki_names[s][:url].index('$1')
          url = @interwiki_names[s][:url].dup.sub(/\$1/, page)
          @plugin.make_anchor(url, display_text)
        else
          @plugin.make_anchor("#{@interwiki_names[s][:url]}#{page}", display_text)
        end
      else
        "#{s}:#{p}".escapeHTML
      end
    end

    def outer_alias(s)
      a = nil
      if @interwiki_names.has_key?(s)
        if @interwiki_names[s][:encoding] == 'alias'
          a = @plugin.make_anchor(@interwiki_names[s][:url], s.escapeHTML)
        end
      end
      a
    end
    
    private
    def load_interwiki_names
      n = @db.load( @conf.interwiki_name ) || ''
      n.scan( INTERWIKI_NAME_RE ) do |i|
        e = i.size > 2 ? i[2] : 'none'
        @interwiki_names[i[0]] = {:url => i[1], :encoding => e}
      end
    end
  end
end

# *[[Hiki|http://www.namaraii.com/hiki/hiki.cgi?]] euc
# *[[YukiWiki|http://www.hyuki.com/yukiwiki/wiki.cgi?]] euc
# *[[GoogleJ|http://www.google.co.jp/search?hl=ja&btnG=Google+%8C%9F%8D%F5&lr=lang_ja&q=]] sjis
