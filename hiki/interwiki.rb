# $Id: interwiki.rb,v 1.1.1.1 2003-02-22 04:39:31 hitoshi Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>
# You can redistribute it and/or modify it under the terms of
# the Ruby's licence.

module Hiki
  class InterWiki
    require 'hiki/util'
    
    URL  = '(?:http|https|ftp):\/\/[a-zA-Z0-9;/?:@&=+$,\-_.!~*\'()%]+'
    INTERWIKI_NAME_RE =  /\[\[([^|]+)\|(#{URL})\]\](?:\s+(sjis|euc))?/

    attr_reader :interwiki_names
    
    def initialize(db)
      @db = db
      @interwiki_names = Hash::new
      
      load_interwiki_names
    end

    def interwiki(s, p)
      if @interwiki_names.has_key? (s)
        page = case @interwiki_names[s][:encoding]
               when 'sjis'
                 p.to_sjis
               when 'euc'
                 p.to_euc
               else
                 p
               end.escape
        if @interwiki_names[s][:url].index('$1')
          url = @interwiki_names[s][:url].dup.sub(/\$1/, page)
          %Q!<a href="#{url}">#{s.escapeHTML}:#{p.escapeHTML}</a>!
        else
          %Q!<a href="#{@interwiki_names[s][:url]}#{page}">#{s.escapeHTML}:#{p.escapeHTML}</a>!
        end
      else
        "#{s}:#{p}".escapeHTML
      end
    end

    private
    def load_interwiki_names
      n = @db.load( $interwiki_name ) || ''
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
