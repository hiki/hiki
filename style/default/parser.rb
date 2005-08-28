# $Id: parser.rb,v 1.19 2005-08-28 03:07:54 yanagita Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

require 'cgi'

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
    
    attr_reader :stack

    REF_OPEN   = "[["
    REF_CLOSE  = "]]"
    BAR        = "|"
    EMPHASIS   = "''"
    STRONG     = "'''"
    DELETE     = "=="
    URL        = '(?:http|https|ftp|mailto|file):[a-zA-Z0-9;/?:@&=+$,\-_.!~*\'()#%]+'
    REF        = '\[\[(.+?)\]\]'
    INTERWIKI  = '\[\[([^\]:]+?):([^\]]+)\]\]'
    WIKINAME   = '((?:[A-Z][a-z0-9]+){2,})([^A-Za-z0-9])?'
    IMAGE      = '\.(?:jpg|jpeg|png|gif)'
    PLUGIN     = '\{\{((?:(?!\}\}).)+?)\}\}'
    SPECIAL    = '^\[\]\'=\{\}'
    TABLE      = '\|\|(.*)'
    DEFLIST    = '^:(.+)'
    NEWLINE    = "\000\000\000\000"

    EMPHASIS_RE    = /^#{EMPHASIS}/
    STRONG_RE      = /^#{STRONG}(?!:')/
    DELETE_RE      = /^#{DELETE}/
    NORMAL_TEXT_RE = /^[^#{SPECIAL}]+/
    URL_RE         = /^#{URL}/
    WIKINAME_RE    = /^#{WIKINAME}/
    REF_RE         = /^#{REF}/
    IMAGE_RE       = /#{IMAGE}$/i
    PLUGIN_RE      = /^#{PLUGIN}/
    TABLE_RE       = /^#{TABLE}/
    DEFLIST_RE     = /#{DEFLIST}/

    def initialize( conf )
      @conf           = conf
      @stack          = []
      @cur_stack      = []
      @last_blocktype = []
    end

    def parse( s )
      @stack.clear
      @cur_stack.clear
      @last_blocktype.clear

      s.gsub!(/^([^\s][^\n]*|)#{PLUGIN}/m) {|i| i.gsub(/\n/, NEWLINE)}
      s.each do |line|
        parse_line( line )
        @stack << normalize_line( @cur_stack ).dup
        @cur_stack.clear
      end
      normalize( @stack.flatten )
    end

    def inline( str )
      return unless str

      opened_tags = []
      while str.size > 0 do
        str = inline_impl( str, opened_tags )
      end
      @cur_stack
    end

    private
    def parse_line( line )
      case line
      when %r|^//|
        # comment
      when /^(\!{1,5})(.+)$/
        @cur_stack.push( {:e => :heading_open, :lv => $1.size} )
        inline( $2 )
        @cur_stack.push( {:e => :heading_close, :lv => $1.size} )
      when /^----/
        @cur_stack.push( {:e => :horizontal_rule} )
      when /^(\*{1,3})(.+)$/
        @cur_stack.push( {:e => :unordered_list, :lv => $1.size} )
        @cur_stack.push( {:e => :listitem_open} )
        inline( $2 )
        @cur_stack.push( {:e => :listitem_close} )
      when /^(\#{1,3})(.+)$/
        @cur_stack.push( {:e => :ordered_list, :lv => $1.size} )
        @cur_stack.push( {:e => :listitem_open} )
        inline( $2 )
        @cur_stack.push( {:e => :listitem_close} )
      when /^""(.*)$/
        @cur_stack.push( {:e => :blockquote, :s => $1} )
      when /^:(.+)$/
        @cur_stack.push( {:e => :definition_list} )
        str = $1
        term_flag = /^:/ !~ str
        @cur_stack.push( {:e => :definition_term_open} ) if term_flag
        cur_stack_backup = @cur_stack
        @cur_stack = []
        inline( str )
        tmp_stack = @cur_stack
        @cur_stack = cur_stack_backup
        tmp_stack.each do |elem|
          if elem[:e] == :normal_text && /^(.*?):(.*)$/ =~ elem[:s]
            @cur_stack.push( {:e => :normal_text, :s => $1 } ) unless $1.empty?
            @cur_stack.push( {:e => :definition_term_close} ) if term_flag
            @cur_stack.push( {:e => :definition_desc_open} )
            @cur_stack.push( {:e => :normal_text, :s => $2 } )
          else
            @cur_stack.push( elem )
          end
        end
        @cur_stack.push( {:e => :definition_desc_close} )
      when /^$/
        @cur_stack.push( {:e => :empty} )
      when /^\s(.*)/m
        @cur_stack.push( {:e => :pre, :s => $1} )
      when /^#{TABLE}/
        @cur_stack.push( {:e => :table} )
        @cur_stack.push( {:e => :table_row_open} )
        $1.split( /\|\|/ ).each do |s|
          rw = 1
          cl = 1
          case s
          when /\A!(.*)/
            s = $1
            t = 'th'
          else
            t = 'td'
          end
          case s
          when /\A([\^>]+)(.*)/
            rw = $1.count("^") + 1
            cl = $1.count(">") + 1
            s = $2
          end
          case t
          when 'th'
            @cur_stack.push( {:e => :table_head_open, :row => rw, :col => cl} )
            inline(s)
            @cur_stack.push( {:e => :table_head_close} )
          else
            @cur_stack.push( {:e => :table_data_open, :row => rw, :col => cl} )
            inline(s)
            @cur_stack.push( {:e => :table_data_close} )
          end
       end
        @cur_stack.push( {:e => :table_row_close} )
      when /#{PLUGIN_RE}$/
        if @conf.use_plugin
          @cur_stack.push( {:e => :plugin, :method => $1.gsub(/#{NEWLINE}/, "\n")} )
        else
          inline( line )
        end
      else
        inline( line )
      end
    end
    protected :parse_line

    def inline_impl( str, opened_tags )
      case str
      when STRONG_RE
        if opened_tags.index( :strong )
          @cur_stack.push( {:e => :strong_close} )
          opened_tags.delete( :strong )
        else
          @cur_stack.push( {:e => :strong_open} )
          opened_tags.push( :strong )
        end
        str = $'
      when EMPHASIS_RE
        if opened_tags.index( :emphasis )
          @cur_stack.push( {:e => :emphasis_close} )
          opened_tags.delete( :emphasis )
        else
          @cur_stack.push( {:e => :emphasis_open} )
          opened_tags.push( :emphasis )
        end
        str = $'
      when DELETE_RE
        if opened_tags.index( :delete )
          @cur_stack.push( {:e => :delete_close} )
          opened_tags.delete( :delete )
        else
          @cur_stack.push( {:e => :delete_open} )
          opened_tags.push( :delete )
        end
        str = $'
      when REF_RE
        str = $'
        matched = $1
        if /\A(?:(.+)\|)?(.+)\z/ =~ matched
          s = $1
          href = $2
          if URL_RE =~ href
            if IMAGE_RE =~ href
              h = {:e => :image, :href => CGI::escapeHTML(href)}
            else
              h = {:e => :reference, :href => CGI::escapeHTML(href)}
            end
          elsif /\A(.+?):(.+)\z/ =~ href
            disp = s ? s : "#{$1}:#{$2}"
            h = {:e => :interwiki, :href => $1, :p => $2, :s => disp}
          elsif /\A:(.+)\z/ =~ href
            s = s ? s : $1
            h = {:e => :reference, :href => CGI::escapeHTML($1)}
          else
            h = {:e => :bracketname, :href => href}
          end
          h[:s] = s || href unless h.key?(:s)
          @cur_stack.push( h )
        end
      when URL_RE
        href = $&
        str  = $'
        @cur_stack.push( {:e => :reference, :href => href, :s => href} )
      when PLUGIN_RE
        if @conf.use_plugin
          str = $'
          @cur_stack.push( {:e => :inline_plugin, :method => $1.gsub(/#{NEWLINE}/, "\n")} )
        else
          @cur_stack.push( {:e => :normal_text, :s => str} )
          str = ''
        end
      when WIKINAME_RE
        str = ($2 || "") + $'
        @cur_stack.push( {:e => :wikiname, :s => $1, :href => $1} )
      when NORMAL_TEXT_RE
        m = $&
        after = $'
        if /([^a-zA-Z\d]+)((?:#{WIKINAME})|(?:#{URL}))/ =~ m
          @cur_stack.push( {:e => :normal_text, :s => $` + $1} )
          str = $2 + $' + after
        else
          @cur_stack.push( {:e => :normal_text, :s => m} )
          str = after
        end
      else
        if /^(.+?)([#{SPECIAL}])/ =~ str
          @cur_stack.push( {:e => :normal_text, :s => $1} )
          str = $2 + $'
        else
          @cur_stack.push( {:e => :normal_text, :s => str} )
          str = ''
        end
      end
      str
    end

    def normalize(s)
      ns = []
      last_type = nil
      block_level = Hash::new(0)

      s.each do |e|
        normalize_element( e, ns, block_level, last_type )
        last_type = e[:e]
      end
      close_blocks( ns, block_level )
      ns
    end

    def normalize_element( e, ns, block_level, last_type )
      type = e[:e]
      case type
      when :horizontal_rule, :plugin
        close_blocks( ns, block_level )
        ns.push( e )
      when :heading_open
        close_blocks( ns, block_level )
        e[:e] = "heading#{e[:lv]}_open".intern
        ns.push( e )
        @last_blocktype.push(type)
      when :heading_close
        e[:e] = "heading#{e[:lv]}_close".intern
        ns.push( e )
        @last_blocktype.clear
      when :empty
        close_blocks( ns, block_level )
      when :unordered_list, :ordered_list
        close_blocks( ns, block_level ) if type != @last_blocktype.last
        cur_lv = e[:lv]
        blk_lv = block_level[type]

        if cur_lv > blk_lv
          (cur_lv - blk_lv).times do
            ns.push( {:e => "#{type}_open".intern})
          end
        elsif cur_lv < blk_lv
          (blk_lv - cur_lv).times { ns.push({:e => "#{type}_close".intern}) }
        end

        @last_blocktype.push(type)
        block_level[type] = cur_lv
      when :listitem_open
        @last_blocktype.push(type)
        ns.push( e )
      when :listitem_close
        @last_blocktype.delete_at(@last_blocktype.rindex(:listitem_open)) if @last_blocktype.rindex(:listitem_open)
        ns.push( e )
      when :blockquote
        if !@last_blocktype.index(type)
          close_blocks( ns, block_level )
          ns.push( {:e => "#{type}_open".intern} )
          @last_blocktype.push(type)
        end

        if @last_blocktype.last != :p
          ns.push( {:e => :p_open} )
          @last_blocktype.push(:p)
        end

        e[:e] = :normal_text
        ns.push( e )

        if e[:s].size == 0
          ns.push( {:e => :p_close} )
          @last_blocktype.pop
        end
      when :pre
        if type != @last_blocktype.last
          close_blocks( ns, block_level )
          ns.push( {:e => "#{type}_open".intern} )
          @last_blocktype.push(type)
        end
        e[:e] = :normal_text
        ns.push( e )
      when :table
        if type != @last_blocktype.last
          close_blocks( ns, block_level )
          ns.push( {:e => "#{type}_open".intern} )
          @last_blocktype.push(type)
        end
      when :definition_list
        if type != @last_blocktype.last
          close_blocks( ns, block_level )
          ns.push( {:e => "#{type}_open".intern} )
          @last_blocktype.push(type)
        end
      when :emphasis_close, :strong_close, :delete_close
        ns.push( e )
      when :plugin
        close_blocks( ns, block_level )
        ns.push( e )
      else
        if (@last_blocktype.index(:pre) || @last_blocktype.index(:blockquote) ||
           (@last_blocktype.index(:list_item) && last_type == :list_item_close) ||
           (@last_blocktype.index(:table) && last_type == :table_row_close) ||
           (@last_blocktype.index(:definition_list) && last_type == :definition_desc_close) ||
           (@last_blocktype.index(:ordered_list) && @last_blocktype.last != :listitem_open) ||
           (@last_blocktype.index(:unordered_list) && @last_blocktype.last != :listitem_open))
          close_blocks( ns, block_level )
        end

        if @last_blocktype.empty?
          ns.push( {:e => :p_open} )
          @last_blocktype.push(:p)
        end
        ns.push( e )
      end
    end

    def close_blocks( ns, lv )
      while b = @last_blocktype.pop do
        case b
        when nil
        when :unordered_list, :ordered_list
          lv[b].times { ns.push( {:e => "#{b}_close".intern} ) }
          lv[b] = 0
        else
          ns.push( {:e => "#{b}_close".intern} )
        end
      end
    end

    def normalize_line(s)
      normalize_emphasis(s)
      normalize_strong(s)
      normalize_delete(s)
      s
    end

    def normalize_emphasis(s)
      normalize_esd(s, :emphasis_open, :emphasis_close, EMPHASIS)
    end

    def normalize_strong(s)
      normalize_esd(s, :strong_open, :strong_close, STRONG)
    end

    def normalize_delete(s)
      normalize_esd(s, :delete_open, :delete_close, DELETE)
    end

    def normalize_esd(s, e1, e2, to)
      eo = s.find_all{|e| e[:e] == e1}
      ec = s.find_all{|e| e[:e] == e2}
      if (n = eo.size - ec.size) != 0
        n.times do
          pos = s.rindex(eo.pop)
          s[pos][:e] = :normal_text
          s[pos][:s] = to
        end
      end
    end
  end
end
