# $Id: parser.rb,v 1.6 2003-02-23 02:20:08 hitoshi Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

module Hiki
  class HikiStack < Array
    def find( h )
      return nil unless h.instance_of?(Hash)
      key, value = h.shift
      result = []
      self.each { |i|
        if i[key] == value
          result << i
          yield( i ) if block_given?
        end
      }
      result
    end
  end
    
  class Parser
    attr_reader :stack

    REF_OPEN   = "[["
    REF_CLOSE  = "]]"
    BAR        = "|"
    EMPHASIS   = "'''"
    STRONG     = "''"
    DELETE     = "=="
    URL        = '(?:http|https|ftp):\/\/[a-zA-Z0-9;/?:@&=+$,\-_.!~*\'()#%]+'
    REF1       = '\[\[([^\]|]+?)\|([^\]]+?)\]\]'
    REF2       =  '\[\[([^\]]+?)\]\]'
    INTERWIKI  = '\[\[([^:]+?):([^\]]+)\]\]'
    WIKINAME   = '((?:[A-Z][a-z0-9]+){2,})([^A-Za-z0-9])'
    IMAGE      = '\.(?:jpg|jpeg|png|gif)'
    PLUGIN     = '\{\{(.+?)(?:\((.*?)\))?\s*\}\}'

    EMPHASIS_RE    = /^#{EMPHASIS}/
    STRONG_RE      = /^#{STRONG}(?!:')/
    DELETE_RE      = /^#{DELETE}/
    NORMAL_TEXT_RE = /^[^\[\]'=\{\}]+/
    URL_RE         = /^#{URL}/
    WIKINAME_RE    = /^#{WIKINAME}/
    REF1_RE        = /^#{REF1}/
    REF2_RE        = /^#{REF2}/
    INTERWIKI_RE   = /^#{INTERWIKI}/
    IMAGE_RE       = /#{IMAGE}$/i
    PLUGIN_RE      = /^#{PLUGIN}/

    def parse( s )
      @stack = HikiStack::new
      @cur_stack = HikiStack::new
      @last_blocktype = []

      s.each do |line|
        line.sub! ( /[\n\r]+\z/, '')
        case line
        when /^(\!{1,5})(.+)$/
          @cur_stack.push( {:e => :heading_open, :lv => $1.size} )
          inline( $2 )
          @cur_stack.push( {:e => :heading_close, :lv => $1.size} )
        when /^----/
          @cur_stack.push( {:e => :horizontal_rule} )
        when /^(\*{1,3})(.+)$/
          @cur_stack.push( {:e => :unordered_listitem_open, :lv => $1.size} )
          inline( $2 )
          @cur_stack.push({ :e => :unordered_listitem_close} )
        when /^(\#{1,3})(.+)$/
          @cur_stack.push( {:e => :ordered_listitem_open, :lv => $1.size} )
          inline( $2 )
          @cur_stack.push( {:e => :ordered_listitem_close} )
        when /^""(.*)$/
          @cur_stack.push( {:e => :blockquote} )
          inline( $1 )
        when /^:(.+?):(.+)$/
          @cur_stack.push( {:e => :definition_list_open} )
          @cur_stack.push( {:e => :definition_term_open} )
          inline( $1 )
          @cur_stack.push( {:e => :definition_term_close} )
          @cur_stack.push( {:e => :definition_desc_open} )
          inline( $2 )
          @cur_stack.push( {:e => :definition_desc_close} )
          @cur_stack.push( {:e => :definition_list_close} )
        when /^$/
          @cur_stack.push( {:e => :empty} )
        when /^\s(.*)/
          @cur_stack.push( {:e => :pre, :s => $1} )
        when /^#{PLUGIN}\s*$/
          if $use_plugin
            @cur_stack.push( {:e => :plugin, :method => $1, :param => $2} )
          else
            inline( line )
          end
        else
          inline( line )
        end
        @stack << normalize_line( @cur_stack ).dup
        @cur_stack.clear
      end
      normalize( @stack.flatten )
    end

    private
    def inline( str )
      return unless str
      a = []
      
      while str.size > 0 do
        case str
        when EMPHASIS_RE
          if a.index( :emphasis_close )
            @cur_stack.push ( {:e => :emphasis_close} )
            a.delete( :emphasis_close )
          else
            @cur_stack.push ( {:e => :emphasis_open} )
            a << :emphasis_close
          end
          str = $'
        when STRONG_RE
          if a.index( :strong_close )
            @cur_stack.push ( {:e => :strong_close} )
            a.delete( :strong_close )
          else
            @cur_stack.push ( {:e => :strong_open} )
            a << :strong_close
          end
          str = $'
        when DELETE_RE
          if a.index( :delete_close )
            @cur_stack.push ( {:e => :delete_close} )
            a.delete( :delete_close )
          else
            @cur_stack.push ( {:e => :delete_open} )
            a << :delete_close
          end
          str = $'
        when REF1_RE
          href = $2
          s    = $1
          str  = $'
          match_pattern = $&
          
          if /^#{URL}$/ =~ href
            if IMAGE_RE =~ href
              @cur_stack.push ( {:e => :image, :href => href.escapeHTML, :s => s} )
            else
              @cur_stack.push ( {:e => :reference, :href => href.escapeHTML, :s => s} )
            end
          else
            @cur_stack.push ( {:e => :normal_text, :s => match_pattern} )
          end
        when URL_RE
          href = $&
          str  = $'
          @cur_stack.push ( {:e => :reference, :href => href, :s => href} )
        when INTERWIKI_RE
          @cur_stack.push ( {:e => :interwiki, :href => $1, :s => $2} )
          str = $'
        when REF2_RE
          str = $'
          @cur_stack.push ( {:e => :wikiname, :s => $1} )
        when PLUGIN_RE
          if $use_plugin
            @cur_stack.push( {:e => :inline_plugin, :method => $1, :param => $2} )
            str = $'
          else
            @cur_stack.push ( {:e => :normal_text, :s => str} )
            str = ''
          end
        when WIKINAME_RE
          str = $2 + $'
          @cur_stack.push ( {:e => :wikiname, :s => $1} )
        when NORMAL_TEXT_RE
          m = $&
          after = $'
          if /([^a-zA-Z\d]+)((?:#{WIKINAME})|(?:#{URL}))/ =~ m
            @cur_stack.push ( {:e => :normal_text, :s => $` + $1} )
            str = $2 + $' + after
          else
            @cur_stack.push ( {:e => :normal_text, :s => m} )
            str = after
          end
        else
          @cur_stack.push ( {:e => :normal_text, :s => str} )
          str = ''
        end
      end
    end

    def normalize(s)
      ns = HikiStack::new
      last_type = nil
      block_level = Hash::new(0)

      s.each do |e|
        type = e[:e]
        case type
        when :horizontal_rule, :plugin
          close_blocks( ns, block_level )
          ns.push ( e )
        when :heading_open
          close_blocks( ns, block_level )
          e[:e] = "heading#{e[:lv]}_open".intern
          ns.push ( e )
          @last_blocktype.push type
        when :heading_close
          e[:e] = "heading#{e[:lv]}_close".intern
          ns.push ( e )
          @last_blocktype.clear
        when :empty
          close_blocks( ns, block_level )
        when :unordered_listitem_open, :ordered_listitem_open
          t = type.to_s
          t.sub!( /item_open/, '' )
          t = t.intern
          close_blocks( ns, block_level ) if t != @last_blocktype.last
          cur_lv = e[:lv]
          blk_lv = block_level[t]
          if cur_lv > blk_lv
            (cur_lv - blk_lv).times do
              ns.push( {:e => "#{t}_open".intern})
              ns.push( {:e => :listitem_open} )
            end
          elsif cur_lv < blk_lv
            (blk_lv - cur_lv).times { ns.push({:e => "#{t}_close".intern}) }
          else
            ns.push( {:e => :listitem_open} )
          end
          @last_blocktype.push t
          block_level[t] = cur_lv
        when :unordered_listitem_close, :ordered_listitem_close
          ns.push ( {:e => :listitem_close} )
        when :pre, :p, :blockquote
          if type != @last_blocktype.last
            close_blocks( ns, block_level )
            ns.push( {:e => "#{type}_open".intern} )
            @last_blocktype.push type
          end
          e[:e] = :normal_text if type == :pre
          ns.push( e ) 
          @last_blocktype.push(type) if @last_blocktype.last != type
        when :emphasis_close, :strong_close, :delete_close
          ns.push ( e )
        when :blockquote_close
        else
          if @last_blocktype.empty?
            ns.push( {:e => :p_open} )
            @last_blocktype.push :p
          end
          ns.push ( e )
        end
        last_type = e[:e]
      end
      close_blocks( ns, block_level )
      ns
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
      eo = s.find( :e => e1 )
      ec = s.find( :e => e2 )
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

if __FILE__ == $0
  require 'html_formatter'
  
  p =  Hiki::Parser::new.parse( ARGF )
  h = Hiki::HTMLFormatter::new( p )
  puts h.to_s
  puts h.toc
end
