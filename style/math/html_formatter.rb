# $Id: html_formatter.rb,v 1.1 2004-12-22 04:43:04 fdiary Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

require 'hiki/util'
require "style/default/html_formatter"
require "style/math/latex.rb"

module Hiki
  class HTMLFormatter_math < HTMLFormatter_default
    def initialize( s, db, plugin, conf, suffix = 'l')
      super( s, db, plugin, conf, suffix )
      @math = nil
    end

    private
    def map(key)
      case key
      when :displaymath_open
        '<div class="displaymath">'
      when :displaymath_close
        '</div>'
      else
        super(key)
      end
    end

    def token_to_s( t, s )
      case t[:e]
      when :math_text
        s[:html] << math().text_mode(t[:s])
      when :math_display
        s[:html] << math().display_mode(t[:s])
      else
        super( t, s )
      end
    end

    def math
      if @math.nil?
        @math = Math_latex.new(@conf, @plugin.instance_eval{@page})
      end
      @math
    end
  end
end
