# $Id: html_formatter.rb,v 1.3 2003-02-22 08:28:47 hitoshi Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

require 'hiki/util'
require 'hiki/interwiki'

module Hiki
    
  class HTMLFormatter
    MAP = Hash::new
    MAP[:heading1_open]        = '<h2>'
    MAP[:heading1_close]       = '</h2>'
    MAP[:heading2_open]        = '<h3>'
    MAP[:heading2_close]       = '</h3>'
    MAP[:heading3_open]        = '<h4>'
    MAP[:heading3_close]       = '</h4>'
    MAP[:heading4_open]        = '<h5>'
    MAP[:heading4_close]       = '</h5>'
    MAP[:heading5_open]        = '<h6>'
    MAP[:heading5_close]       = '</h6>'
    MAP[:horizontal_rule]      = '<hr>'
    MAP[:unordered_list_open]  = '<ul>'
    MAP[:unordered_list_close] = '</ul>'
    MAP[:ordered_list_open]    = '<ol>'
    MAP[:ordered_list_close]   = '</ol>'
    MAP[:listitem_open]        = '<li>'
    MAP[:listitem_close]       = '</li>'
    MAP[:blockquote_open]      = '<blockquote>'
    MAP[:blockquote_close]     = '</blockquote>'
    MAP[:definition_list_open] = '<dl>'
    MAP[:definition_list_close]= '</dl>'
    MAP[:definition_term_open] = '<dt>'
    MAP[:definition_term_close]= '</dt>'
    MAP[:definition_desc_open] = '<dd>'
    MAP[:definition_desc_close]= '</dd>'
    MAP[:pre_open]             = '<pre>'
    MAP[:pre_close]            = '</pre>'
    MAP[:p_open]               = '<p>'
    MAP[:p_close]              = '</p>'
    MAP[:emphasis_open]        = '<em>'
    MAP[:emphasis_close]       = '</em>'
    MAP[:strong_open]          = '<strong>'
    MAP[:strong_close]         = '</strong>'
    MAP[:delete_open]          = '<del>'
    MAP[:delete_close]         = '</del>'
    
    def initialize( s, db, plugin, suffix = 'l')
      @tokens     = s
      @db         = db
      @plugin     = plugin
      @suffix     = suffix
      @toc_cnt    = 0
      @toc        = Array::new
      @references = Array::new
      @interwiki  = InterWiki::new( @db )
    end

    def HTMLFormatter::diff ( d )
      s = ''
      d.each do |l|
        lines = l[2]
        case l[0]
        when :+
          s << "<span class=added>#{lines.join.escapeHTML}</span>\n"
        when :-
          s << "<span class=deleted>#{lines.join.escapeHTML}</span>\n"
        end
      end
      s
    end

    def to_s
      html        = ''
      toc_level   = 0
      toc_title   = ''
      normal_text = ''
      pre         = false
      
      @tokens.each do |t|
        if (normal_text.size > 0 && t[:e] != :normal_text)
          normal_text.chomp!
          html << normal_text
          html << "\n" if pre
          normal_text = ''
        end
        
        case t[:e]
        when :normal_text
          if pre
            html << "#{t[:s].escapeHTML}\n"
          else
            normal_text << "#{t[:s].escapeHTML}"
            toc_title << t[:s] if toc_level > 0
          end
        when :reference
          html << %Q!<a href="#{t[:href]}">#{t[:s].escapeHTML}</a>!
          toc_title << t[:s] if toc_level > 0
        when :wikiname
          if @db.exist?( t[:s] )
            html << "<a href=\"#{$cgi_name }?#{t[:s].escape}\">#{t[:s].escapeHTML}</a>"
            @references << t[:s]
          else
            html <<  "#{t[:s].escapeHTML}<a href=\"#{$cgi_name }?c=edit&p=#{t[:s].escape}\">?</a>"
          end
          toc_title << t[:s] if toc_level > 0
        when :interwiki
          html << @interwiki.interwiki(t[:href], t[:s])
        when :empty
          html << "\n"
        when :heading1_open, :heading2_open, :heading3_open, :heading4_open, :heading5_open
          toc_level = t[:lv]
          html << %Q!#{MAP[t[:e]]}<a name="#{@suffix}#{@toc_cnt}"> </a>!
        when :heading1_close, :heading2_close, :heading3_close, :heading4_close, :heading5_close
          add_toc( toc_level, toc_title )
          toc_level = 0
          toc_title = ''
          html << "#{MAP[t[:e]]}\n"
        when :image
          html << %Q!<img src = "#{t[:href]}" alt = "#{t[:s].escapeHTML}">!
        when :plugin, :inline_plugin
          tag = ( t[:e] == :plugin ) ? 'div' : 'span'
          begin
            s = call_plugin_method( t )
            if s.class == String
              html << %Q!<#{tag} class = "plugin">!
              html << s
              html << "</#{tag}>"
            end
          rescue Exception
            html << plugin_error( t[:method], $! )
          end
        else
          if t[:e] == :pre_open
            pre = true
          elsif t[:e] == :pre_close
            pre = false
          end

          html << "#{MAP[t[:e]]}\n"
        end
      end
      html
    end

    def references
      @references.uniq
    end    

    def toc
      s = "#{MAP[:unordered_list_open]}\n"
      lv = 1
      @toc.each do |h|
        if h['level'] > lv
          s << ( "#{MAP[:unordered_list_open]}\n" * ( h['level'] - lv ) )
          lv = h['level']
        elsif h['level'] < lv
          s << ( "#{MAP[:unordered_list_close]}\n" * ( lv - h['level'] ) )
          lv = h['level']
        end
        s << %Q!#{MAP[:listitem_open]}<a href="#l#{h['index']}">#{h['title'].escapeHTML}</a>\n!
      end
      s << ("#{MAP[:unordered_list_close]}\n" * lv)
    end
    

    private
    def add_toc( level, title )
      @toc << {"level" => level, "title" => title, "index" => @toc_cnt}
      @toc_cnt = @toc_cnt + 1
    end

    def call_plugin_method( t )
      return nil unless $use_plugin
      
      method = t[:method]
      args = nil
      
      if t[:param]
        args = csv_split( t[:param] ).collect! do |a|
          case a
          when /^[-+]?\d+(\.\d+)?$/
            $1 ? a.to_f : a.to_i
          when /^'(.+)'$/, /^"(.+)"$/
            $1
          else
            a
          end
        end
      end

      begin
        if @plugin.respond_to?( method ) && !Object.method_defined?( method )
          if args
            @plugin.send( method, *args )
          else
            @plugin.send( method )
          end
        else
          raise PluginException, 'not plugin method'
        end
      rescue
        raise PluginException, $!.message
      end
    end
  end
end
