# $Id: html_formatter.rb,v 1.2 2005-01-28 19:35:08 fdiary Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

require 'hiki/util'
require "style/default/html_formatter"
require "style/math/latex.rb"

module Hiki
  class HTMLFormatter_math < HTMLFormatter_default
    def initialize( s, db, plugin, conf, suffix = 'l')
      super( s, db, plugin, conf, suffix )
      @save_text = ''
      @last_mode = nil
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
        if @last_mode and @last_mode != :math_text then
          s[:html] << math().text_mode(@save_text)
          @save_text = '' 
        else
          @save_text += t[:s]
        end
        @last_mode = :math_text
      when :math_display
        if @last_mode and @last_mode != :math_display then
          s[:html] << math().display_mode(@save_text)
          @save_text = ''
        else
          @save_text += t[:s]
        end
        @last_mode = :math_display
      else
        if @save_text.size > 0 then
          case @last_mode
          when :math_text
            s[:html] << math().text_mode(@save_text)
          when :math_display
            s[:html] << math().display_mode(@save_text)
          end
          @save_text = ''
        end
        @last_mode = nil
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
