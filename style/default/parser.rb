# $Id: parser.rb,v 1.22 2005-12-28 22:42:55 fdiary Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

require 'style/default/hikidoc'

module Hiki
  class Parser_default

    class << self
      def heading( str, level = 1 )
        '!' * level + str
      end

      def link( link_str, str = nil )
        str ? "[[#{str}|#{link_str}]]" : "[[#{link_str}]]"
      end

      def blockquote( str )
        str.split(/\n/).collect{|s| %Q|""#{s}\n|}.join
      end
    end
    
    def initialize( conf )
    end

    def parse( s, top_level = 2 )
      HikiDoc.new( s, :level => top_level ).to_html
    end
  end
end
