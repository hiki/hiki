# $Id: html_formatter.rb,v 1.4 2005-09-29 04:53:01 fdiary Exp $

require 'hiki/util'
require "style/default/html_formatter"
require "style/math/latex.rb"

module Hiki
  class HTMLFormatter_math < HTMLFormatter_default
    include Hiki::Util
    def to_s
      super
      @html_converted = replace_math( @html_converted )
    end

    private

    def replace_math( text )
      replace_inline( text ) do |str|
        str.gsub!( /\[\$(.+?)\$\]/ ) do |match|
          math.text_mode(unescape_html($1) )
        end
        str.gsub!( /(^\$\$.*\n?)+/ ) do |match|
          '<div class="displaymath">%s</div>' % 
            math.display_mode( unescape_html(match).gsub( /^\$\$/, '' ) )
        end
      end
    end

    def math
      @math ||= Math_latex.new(@conf, @plugin.instance_eval{@page})
    end
  end
end
