# anchorlist.rb for Hiki/RD+
#
# Copyright (c) 2003 Masao Mutoh<mutoh@highway.ne.jp>
# You can redistribute it and/or modify it under GPL2.
#
# Original: a.rb is from tDiary <http://www.tdiary.org/>
# a.rb -
# Copyright (c) 2002,2003 MUTOH Masao <mutoh@highway.ne.jp>
# You can redistribute it and/or modify it under GPL2.
#
require "nkf"
require "hiki/util"

module Hiki
  class AnchorList
    include Hiki::Util

    REG_PIPE = /\|/
    REG_COLON = /\:/
    REG_URL = /:\/\//
    REG_CHARSET = /euc|sjis|jis/
    REG_CHARSET2 = /sjis|jis/
    REG_CHARSET3 = /euc/
    URL  = '(?:http|https|ftp|mailto|file):\/\/[a-zA-Z0-9;/?:@&=+$,\-_.!~*\'()%#]+'
    REG_INTERWIKI_NAME =  /\[\[([^|]+)\|(#{URL})\]\](?:\s+(sjis|euc))?/


    def initialize(interwiki_data, plugin)
      @anchors = {}
      @plugin = plugin
      n = interwiki_data || ""
      n.scan(REG_INTERWIKI_NAME) do |i|
        @anchors[i[0]] = [i[1], "", i.size > 2 ? i[2] : ""]
      end
    end

    def separate(word)
      if REG_PIPE =~ word
        name, data = $`, $'
      else
        name, data = nil, word
      end

      option = nil
      if data =~ REG_URL
        key = data
      elsif data =~ REG_COLON
        key, option = $`, $'
      else
        key = data # Error pattern
      end
      [key, option, name]
    end

    def convert_charset(option, charset)
      return "" unless option
      return option unless charset
      if charset =~ REG_CHARSET2
      ret = escape(NKF.nkf("-#{charset[0].chr}", option))
      elsif charset =~ REG_CHARSET3
        ret = escape(option)
      else
        ret = option
      end
      ret
    end

    def data(key)
      data = @anchors[key]
      if data
        data.collect{|v| v ? v.dup : nil}
      else
        [nil, nil, nil]
      end
    end

    def create_anchor(key, option_or_name = nil, name = nil, charset = nil)
      url, value, cset = data(key)
      if url.nil?
        key, option, name = separate(key)
        url, value, cset = data(key)
        option_or_name = option unless option_or_name
      end
      charset = cset unless charset
      option_or_name = "#{option_or_name}" if option_or_name
      value = "#{key}:#{option_or_name}" if value == ""

      if url.nil?
        url = key
        if name
          value = name
          url += convert_charset(option_or_name, charset)
        elsif option_or_name
          value = option_or_name
        else
          value = key
        end
      else
        url += convert_charset(option_or_name, charset)
        value = name if name
      end
      %Q[<a href="#{url}">#{value}</a>]
    end

    def has_key?(key)
      @anchors.has_key?(key)
    end
  end
end

