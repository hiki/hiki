# $Id: html_formatter.rb,v 1.4 2005-09-29 04:53:01 fdiary Exp $

require 'hiki/util'
require "style/default/html_formatter"
require "style/math/latex.rb"

module Hiki
  class HTMLFormatter_math < HTMLFormatter_default
    def to_s
      super
      @html_converted = replace_math( @html_converted )
    end

    private

    def replace_math( text )
      replace_inline( text ) do |str|
        str.gsub!( /\[\$(.+?)\$\]/ ) do |match|
          math.text_mode( $1.unescapeHTML )
        end
        str.gsub!( /(^\$\$.*\n?)+/ ) do |match|
          '<div class="displaymath">%s</div>' % 
            math.display_mode( match.unescapeHTML.gsub( /^\$\$/, '' ) )
        end
      end
    end

    def math
      @math ||= Math_latex.new(@conf, @plugin.instance_eval{@page})
    end
  end
end
