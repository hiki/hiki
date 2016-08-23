# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

require "hiki/util"

module Hiki
  class InterWiki
    include Hiki::Util

    URL  = '(?:http|https|ftp|mailto|file):[a-zA-Z0-9;/?:@&=+$,\-_.!~*\'()#%]+'
    INTERWIKI_NAME_RE =  /\[\[([^|]+)\|(#{URL})\]\](?:\s+(sjis|euc|utf8|alias))?/

    attr_reader :interwiki_names

    def initialize(str)
      @interwiki_names = {}
      (str || "").scan(INTERWIKI_NAME_RE) do |i|
        e = i.size > 2 ? i[2] : "none"
        @interwiki_names[i[0]] = {url: i[1], encoding: e}
      end
    end

    def interwiki(s, p, display_text = h("#{s}:#{p}"))
      if @interwiki_names.has_key?(s)
        encoding = @interwiki_names[s][:encoding]
        page = case encoding
               when "sjis"
                 escape(p.encode("Shift_JIS"))
               when "euc"
                 escape(p.encode("EUC-JP"))
               when "utf8"
                 escape(p.encode("UTF-8"))
               else
                 p
               end
        if @interwiki_names[s][:url].index("$1")
          [h(@interwiki_names[s][:url].dup.sub(/\$1/, page)), display_text]
        else
          [h("#{@interwiki_names[s][:url]}#{page}"), display_text]
        end
      else
        nil
      end
    end

    def outer_alias(s)
      if @interwiki_names.has_key?(s) && @interwiki_names[s][:encoding] == "alias"
        return [h(@interwiki_names[s][:url]), h(s)]
      else
        return nil
      end
    end
  end
end

# *[[Hiki|http://hikiwiki.org/ja/?]] euc
# *[[YukiWiki|http://www.hyuki.com/yukiwiki/wiki.cgi?]] euc
# *[[GoogleJ|http://www.google.co.jp/search?hl=ja&btnG=Google+%8C%9F%8D%F5&lr=lang_ja&q=]] sjis
