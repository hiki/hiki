# $Id: html_formatter.rb,v 1.22 2005-03-05 15:24:29 hitoshi Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

require 'hiki/util'
require 'hiki/interwiki'
require 'hiki/aliaswiki'
require 'hiki/hiki_formatter'

module Hiki
    
  class HTMLFormatter_default < HikiFormatter
    MAP = Hash::new
    MAP[:heading1_open]        = '<h2><span class="date">'
    MAP[:heading1_open_end]    = '</span><span class="title">'
    MAP[:heading1_close]       = '</span></h2>'
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
    MAP[:listitem_close]       = ''
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
    MAP[:table_open]           = '<table border="1">'
    MAP[:table_close]          = '</table>'
    MAP[:table_row_open]       = '<tr>'
    MAP[:table_row_close]      = '</tr>'
    MAP[:table_data_open]      = '<td>'
    MAP[:table_data_close]     = '</td>'

    def initialize( s, db, plugin, conf, suffix = 'l')
      @tokens     = s
      @db         = db
      @plugin     = plugin
      @conf       = conf
      @suffix     = suffix
      @toc_cnt    = 0
      @toc        = Array::new
      @references = Array::new
      @interwiki  = InterWiki::new( @db, plugin, @conf )
      @aliaswiki  = AliasWiki::new( @db, @conf )
      @auto_links  = get_auto_links if @conf.auto_link
    end

    def flush_normal_text(text, pre)
      if not pre and @conf.auto_link
        auto_link(text)
      else
        text 
      end
    end
    private :flush_normal_text

    def to_s
      s = {
        :html        => '',
        :toc_level   => 0,
        :toc_title   => '',
        :normal_text => '',
        :pre         => false,
      }
      
      @tokens.each do |t|
        if (s[:normal_text].size > 0 && t[:e] != :normal_text)
          s[:html] << flush_normal_text(s[:normal_text], s[:pre])
          s[:normal_text] = ''
        end
        token_to_s( t, s )
      end
      if (s[:normal_text].size > 0)
        s[:html] << flush_normal_text(s[:normal_text], s[:pre])
      end
      s[:html]
    end

    def references
      @references.uniq
    end    

    def toc
      s = %Q!<div class="day"><div class="body"><div class="section">!
      s << "#{map(:unordered_list_open)}\n"
      lv = 1
      @toc.each do |h|
        if h['level'] > lv
          s << ( "#{map(:unordered_list_open)}\n" * ( h['level'] - lv ) )
          lv = h['level']
        elsif h['level'] < lv
          s << ( "#{map(:unordered_list_close)}\n" * ( lv - h['level'] ) )
          lv = h['level']
        end
        s << %Q!#{map(:listitem_open)}<a href="#l#{h['index']}">#{h['title'].escapeHTML}</a>#{map(:listitem_close)}\n!
      end
      s << ("#{map(:unordered_list_close)}\n" * lv)
      s << "</div></div></div>"
    end
    
    def apply_tdiary_theme(orig_html)
      section = ''
      title   = ''
      html    = ''

      orig_html.each do |line|
        if /^<h2>/ =~ line
          html << tdiary_section(title, section) unless title.empty? && section.empty?
          section = ''
          title = line
        else
          section << line
        end
      end
      html << tdiary_section(title, section)
    end

    private
    def map(key)
      MAP[key]
    end

    def token_to_s( t, s )
      case t[:e]
      when :normal_text
        s[:normal_text] << "#{t[:s].escapeHTML}"
        if not s[:pre] and s[:toc_level] > 0
          s[:toc_title] << t[:s]
        end
      when :reference
        s[:html] << @plugin.make_anchor( t[:href], t[:s].escapeHTML )
        s[:toc_title] << t[:s] if s[:toc_level] > 0
      when :wikiname, :bracketname
        disp = t[:s]
        t[:href] = @aliaswiki.aliaswiki_names.key(t[:href]) || t[:href]
        if t[:e] == :bracketname
          orig = @db.select {|p| p[:title] == t[:href]}
          t[:href] = orig[0] if orig[0]
        end
        if !@conf.use_wikiname and t[:e] == :wikiname
          s[:html] << disp.escapeHTML
        elsif @db.exist?( t[:href] )
           s[:html] << @plugin.hiki_anchor(t[:href].escape, disp.escapeHTML)
          @references << t[:href]
        else
          missing_anchor_title = @conf.msg_missing_anchor_title % [ disp.escapeHTML ]
          wikiname_anchor = @plugin.auth? ? "#{disp.escapeHTML}<a class=\"nodisp\" href=\"#{@conf.cgi_name}?c=edit;p=#{t[:href].escape}\" title=\"#{missing_anchor_title}\">?</a>" : disp.escapeHTML
			 #   outer_alias = @interwiki.outer_alias(t[:href]) || "#{disp.escapeHTML}<a class=\"nodisp\" href=\"#{@conf.cgi_name}?c=edit;p=#{t[:href].escape}\" title=\"#{missing_anchor_title}\">?</a>"
          outer_alias = @interwiki.outer_alias(t[:href]) || wikiname_anchor
          s[:html] << outer_alias
        end
        s[:toc_title] << t[:href] if s[:toc_level] > 0
      when :interwiki
        s[:html] << @interwiki.interwiki(t[:href], t[:p], t[:s])
      when :empty
        s[:html] << "\n"
      when :heading1_open, :heading2_open, :heading3_open, :heading4_open, :heading5_open
        s[:toc_level] = t[:lv]
        if t[:e] == :heading2_open
          link_label = %Q[<span class="sanchor">_</span>]
        else
          link_label = ' '
        end
        s[:html] << %Q!#{map(t[:e])}<a name="#{@suffix}#{@toc_cnt}">#{link_label}</a>#{map("#{t[:e]}_end".to_sym)}!
      when :heading1_close, :heading2_close, :heading3_close, :heading4_close, :heading5_close
        add_toc( s[:toc_level], s[:toc_title] )
        s[:toc_level] = 0
        s[:toc_title] = ''
        s[:html] << "#{map(t[:e])}\n"
#        s[:html] << %Q!<a href="#top"><span class="top_anchor">[TOP]</span></a>! if t[:e] == :heading1_close
      when :image
        s[:html] << %Q!<img src = "#{t[:href]}" alt = "#{File.basename( t[:s].escapeHTML )}">!
      when :plugin, :inline_plugin
        begin
          str = call_plugin_method( t )
          if str.class == String
            s[:html] << str
          end
        rescue Exception => e
          if @conf.plugin_debug
            s[:html] << e.message
          else
            s[:html] << plugin_error( t[:method], $! )
          end
        end
      else
        if t[:e] == :pre_open
          s[:pre] = true
        elsif t[:e] == :pre_close
          s[:pre] = false
        elsif t[:e] == :p_close
	  s[:html].chomp!
        end
        s[:html] << "#{map(t[:e])}"
        if [:emphasis_close, :strong_close, :delete_close].index(t[:e]) == nil and /_close\z/ =~ t[:e].to_s
          s[:html] <<  "\n"
        end
      end
    end

    def add_toc( level, title )
      @toc << {"level" => level, "title" => title, "index" => @toc_cnt}
      @toc_cnt = @toc_cnt + 1
    end

    def tdiary_section(title, section)
<<"EOS"
<div class="day">
  #{title.chomp}
  <div class="body">
    <div class="section">
      #{section.chomp}
    </div>
  </div>
</div>
EOS
    end

    def get_auto_links
      pages = Array::new
      @db.page_info.each do |p|
        wikiname_re = /^((?:[A-Z][a-z0-9]+){2,})([^A-Za-z0-9])?/
        if wikiname_re !~ p.keys[0] # not WikiName
           pages << [p.keys[0], p.keys[0]]
        end
        title = p.values[0][:title]
        title = ((title && title.size > 0) ? title : p.keys[0]).escapeHTML
        if wikiname_re !~ title
          pages << [title, title, p.keys[0]]
        end
      end
      @aliaswiki.aliaswiki_names.each {|key, value| pages << [value, value, key]}
      auto_link_array = pages.sort {|a, b| b[1].size <=> a[1].size}
      @auto_links_re = Regexp.new(auto_link_array.collect {|a| Regexp::quote(a[0])}.join('|'))
      auto_link_array
    end

    def auto_link(text)
      return text if @auto_links.size == 0
      text.gsub(@auto_links_re) {|matched|
        page = @auto_links.assoc($&).size > 2 ? @auto_links.assoc($&)[2] : $&
        title = @auto_links.assoc($&)[1]
        @references << page
        @plugin.hiki_anchor(page.escape, title)
      }
    end
      
    def call_plugin_method( t )
      return nil unless @conf.use_plugin
      
      method = t[:method]
      args = nil
      
      if t[:param]
        args = csv_split( t[:param] ).collect! do |a|
          case a
          when /^[-+]?\d+(\.\d+)?$/
            $1 ? a.to_f : a.to_i
          when /^'(.+)'$/, /^"(.+)"$/
            $1.escapeHTML
          else
            a.escapeHTML
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
        raise PluginException, plugin_error('inline plugin', $!)
      end
    end
  end
end
