# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

require "hiki/util"
require "hiki/pluginutil"
require "hiki/interwiki"
require "hiki/aliaswiki"
require "hiki/formatter"
require "uri"

module Hiki
  module Formatter
    class Default < Base
      Formatter.register(:default, self)

      include Hiki::Util

      def initialize(s, db, plugin, conf, prefix = "l")
        @html       = s
        @db         = db
        @plugin     = plugin
        @conf       = conf
        @prefix     = prefix
        @references = []
        @interwiki  = InterWiki.new(@db.load(@conf.interwiki_name))
        @aliaswiki  = AliasWiki.new(@db.load(@conf.aliaswiki_name))
        get_auto_links if @conf.auto_link
      end

      def to_s
        s = @html
        s = replace_inline_image(s)
        s = replace_link(s)
        s = replace_auto_link(s) if @conf.auto_link
        s = replace_heading(s)
        s = replace_plugin(s) if @conf.use_plugin
        @html_converted = s
        s
      end

      def references
        @references.uniq
      end

      HEADING_RE = %r!<h(\d)>.*<a name="l\d+">.*?</a>(.*?)</h\1>!
      TAG_RE = %r!(<.+?>)!

      def toc
        s = "<ul>\n"
        num = -1
        level = 1
        to_s unless @html_converted
        @html_converted.each_line do |line|
          if HEADING_RE =~ line
            new_level = $1.to_i - 1
            num += 1
            title = $2.gsub(TAG_RE, "").strip
            if new_level > level
              s << ("<ul>\n" * (new_level - level))
              level = new_level
            elsif new_level < level
              s << ("</ul>\n" * (level - new_level))
              level = new_level
            end
            s << %Q!<li><a href="\#l#{num}">#{title}</a></li>\n!
          end
        end
        s << ("</ul>\n" * level)
        s
      end

      private

      def replace_inline_image(text)
        text.gsub(/<a href="([^"]+)\.(jpg|jpeg|gif|png)">(.+?)<\/a>/i) do |str|
          %Q|<img src="#{$1}.#{$2}" alt="#{$3}">|
        end
      end

      def replace_auto_link(text)
        return text if @auto_links.empty?
        replace_inline(text) do |str|
          str.gsub!(@auto_links_re) do |match|
            @plugin.hiki_anchor(escape(unescape_html(@auto_links[match])), match)
          end
        end
      end

      PLUGIN_OPEN_RE = /<(span|div) class="plugin">/
      PLUGIN_CLOSE_RE = %r!</(span|div)>!
      LINK_OPEN_RE = /<a .*href=/
      LINK_CLOSE_RE = %r!</a>!
      PRE_OPEN_RE = /<pre>/
      PRE_CLOSE_RE = %r!</pre>!

      def replace_inline(text)
        status = []
        ret = text.split(TAG_RE).collect do |str|
          case str
          when PLUGIN_OPEN_RE
            status << :plugin
          when LINK_OPEN_RE
            status << :a
          when PRE_OPEN_RE
            status << :pre
          when PLUGIN_CLOSE_RE, LINK_CLOSE_RE, PRE_CLOSE_RE
            status.pop
          when TAG_RE
            # do nothing
          else
            if status.empty?
              yield(str)
            end
          end
          str
        end
        ret.join
      end

      URI_RE = /\A#{URI.regexp(%w( http https ftp file mailto ))}\z/

      def replace_link(text)
        text.gsub(%r|<a href="(.+?)">(.+?)</a>|) do |str|
          k, u = $2, $1
          if URI_RE =~ u # uri
            @plugin.make_anchor(u, k, "external")
          else
            u = unescape_html(u)
            u = @aliaswiki.aliaswiki_names.key(u) || u # alias wiki
            if /(.*)(#l\d+)\z/ =~ u
              u, anchor = $1, $2
            else
              anchor = ""
            end
            if @db.exist?(u) # page name
              k = @plugin.page_name(k) if k == u
              @references << u
              if u.empty?
                @plugin.make_anchor(anchor, k)
              else
                @plugin.hiki_anchor(escape(u) + anchor, k)
              end
            elsif orig = @db.select{|i| i[:title] == u}.first # page title
              k = @plugin.page_name(k) if k == u
              u = orig
              @references << u
              @plugin.hiki_anchor(escape(u) + anchor, k)
            elsif outer_alias = @interwiki.outer_alias(u) # outer alias
              @plugin.make_anchor(outer_alias[0] + anchor, k, "external")
            elsif /:/ =~ u # inter wiki ?
              s, p = u.split(/:/, 2)
              if s.empty? # normal link
                @plugin.make_anchor(h(p) + anchor, k, "external")
              elsif inter_link = @interwiki.interwiki(s, unescape_html(p), "#{s}:#{p}")
                @plugin.make_anchor(inter_link[0], k, "external")
              else
                missing_page_anchor(k, u)
              end
            else
              missing_page_anchor(k, u)
            end
          end
        end
      end

      def missing_page_anchor(k, u)
        if @plugin.creatable?
          missing_anchor_title = @conf.msg_missing_anchor_title % [h(u)]
          "#{k}<a class=\"nodisp\" href=\"#{@conf.cgi_name}?c=edit;p=#{escape(u)}\" title=\"#{missing_anchor_title}\">?</a>"
        else
          k
        end
      end

      BLOCKQUOTE_OPEN_RE = /<blockquote>/
      BLOCKQUOTE_CLOSE_RE = %r!</blockquote>!
      HEADING_OPEN_RE = /<h(\d)>/
      HEADING_CLOSE_RE = %r!</h\d>!

      def replace_heading(text)
        status = []
        num = -1
        ret = text.split(TAG_RE).collect do |str|
          case str
          when BLOCKQUOTE_OPEN_RE
            status << :blockquote
          when BLOCKQUOTE_CLOSE_RE
            status.pop
          when HEADING_OPEN_RE
            unless status.include?(:blockquote)
              num += 1
              level = $1.to_i
              status << level
              case level
              when 2
                str << %Q!<span class="date"><a name="#{@prefix}#{num}"> </a></span><span class="title">!
              when 3
                str << %Q!<a name="#{@prefix}#{num}"><span class="sanchor"> </span></a>!
              else
                str << %Q!<a name="#{@prefix}#{num}"> </a>!
              end
            end
          when HEADING_CLOSE_RE
            unless status.include?(:blockquote)
              level = status.pop
              str = "</span>#{str}" if level == 2
            end
          end
          str
        end
        ret.join
      end

      def replace_plugin(text)
        text.gsub(%r!<(span|div) class="plugin">\{\{(.+?)\}\}</\1>!m) do |str|
          tag, plugin_str = $1, $2
          begin
            case tag
            when "span"
              result = @plugin.inline_context{ apply_plugin(plugin_str, @plugin, @conf) }
            when "div"
              result = @plugin.block_context{ apply_plugin(plugin_str, @plugin, @conf) }
            end
            result.class == String ? result : ""
          rescue Exception => e
            $& + e.message
          end
        end
      end

      def get_auto_links
        pages = {}
        @db.pages.each do |p|
          page_h = escape_html(p)
          pages[page_h] = page_h
          title_h = @plugin.page_name(p).gsub(/&quot;/, '"')
          pages[title_h] = page_h unless title_h == page_h
        end
        @aliaswiki.aliaswiki_names.each do |key, value|
          orig_h = escape_html(key)
          alias_h = escape_html(value)
          pages[alias_h] = orig_h
        end
        @auto_links_re = Regexp.union(*pages.keys.sort_by{|i| -i.size})
        @auto_links = pages
      end

      def escape_html(text)
        text.gsub(/&/, "&amp;").
          gsub(/</, "&lt;").
          gsub(/>/, "&gt;")
      end
    end
  end
end
