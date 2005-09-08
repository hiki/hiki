# $Id: parser.rb,v 1.21 2005-09-08 09:51:25 fdiary Exp $
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

    def parse( s )
      HikiDoc.new( s, :level => 2 ).to_html
    end
  end
end
