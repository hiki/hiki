# $Id: parser.rb,v 1.2 2005-01-28 19:35:08 fdiary Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

require "style/default/parser"

module Hiki
  class Parser_math < Parser_default
    attr_reader :stack

    MATH       = '\[\$(.+?)\$\]'
    MATH_RE        = /^#{MATH}/

    def initialize( conf )
      super( conf )
    end

    private
    def parse_line( line )
      case line
      when /^\$\$(.*)$/
        @cur_stack.push( {:e => :displaymath, :s => $1} )
      else
        super( line )
      end
    end

    def inline_impl( str, a )
      case str
      when MATH_RE
        str = $'
        matched = $1
        @cur_stack.push( {:e => :math_text, :s => matched} )
        str
      else
        super( str, a )
      end
    end

    def normalize_element( e, ns, block_level, last_type )
      type = e[:e]
      case type
      when :displaymath
        if !@last_blocktype.index(type)
          close_blocks( ns, block_level )
          ns.push( {:e => "#{type}_open".intern} )
          @last_blocktype.push(type)
        end

        e[:e] = :math_display
        ns.push( e )
      else
        super( e, ns, block_level, last_type )
      end
    end
  end
end
