# $Id: interwiki.rb,v 1.10 2005-12-28 23:42:18 fdiary Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

module Hiki
  class InterWiki
    require 'hiki/util'
    
    URL  = '(?:http|https|ftp|mailto|file):[a-zA-Z0-9;/?:@&=+$,\-_.!~*\'()#%]+'
    INTERWIKI_NAME_RE =  /\[\[([^|]+)\|(#{URL})\]\](?:\s+(sjis|euc|utf8|alias))?/

    attr_reader :interwiki_names
    
    def initialize( str )
      @interwiki_names = Hash::new
      (str || '').scan( INTERWIKI_NAME_RE ) do |i|
        e = i.size > 2 ? i[2] : 'none'
        @interwiki_names[i[0]] = {:url => i[1], :encoding => e}
      end
    end

    def interwiki(s, p, display_text = "#{s}:#{p}".escapeHTML)
      if @interwiki_names.has_key?(s)
        encoding = @interwiki_names[s][:encoding]
        page = case encoding
               when 'sjis'
                 p.to_sjis.escape
               when 'euc'
                 p.to_euc.escape
               when 'utf8'
                 euc_to_utf8(p).escape
               else
                 p
               end
        if @interwiki_names[s][:url].index('$1')
          [@interwiki_names[s][:url].dup.sub(/\$1/, page).escapeHTML, display_text]
        else
          ["#{@interwiki_names[s][:url]}#{page}".escapeHTML, display_text]
        end
      else
        nil
      end
    end

    def outer_alias(s)
      if @interwiki_names.has_key?(s) && @interwiki_names[s][:encoding] == 'alias'
	return [@interwiki_names[s][:url].escapeHTML, s.escapeHTML]
      else
	return nil
      end
    end
  end
end

# *[[Hiki|http://hikiwiki.org/ja/?]] euc
# *[[YukiWiki|http://www.hyuki.com/yukiwiki/wiki.cgi?]] euc
# *[[GoogleJ|http://www.google.co.jp/search?hl=ja&btnG=Google+%8C%9F%8D%F5&lr=lang_ja&q=]] sjis
