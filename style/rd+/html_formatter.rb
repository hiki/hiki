# html_formatter.rb for Hiki/RD+
#
# Copyright (C) 2003 Masao Mutoh <mutoh@highway.ne.jp>
#
# You can redistribute it and/or modify it under the terms of
# the Ruby's licence.
#
# The original html_formatter.rb:
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>
# You can redistribute it and/or modify it under the terms of
# the Ruby's licence.

require 'hiki/util'
require 'hiki/interwiki'
require 'hiki/hiki_formatter'
require 'style/rd+/rd2html.rb'

module Hiki
  class HTMLFormatter_rd < HikiFormatter
    def initialize( s, db, plugin, conf, suffix = 'l')
      @tokens     = s
      @db         = db
      @plugin     = plugin
      @conf       = conf
      @interwiki  = InterWiki::new(@db, @plugin, @conf)
      @visitor = Hiki::RD2HTMLVisitor.new(@plugin, @db, @conf)
    end

    def HTMLFormatter_rd::diff( d, src )
      text = ''
      src = src.split("\n").collect{|s| "#{s.escapeHTML}"}
      si = 0
      di = 0

      d.each do |action,position,elements|
        case action
        when :-
          while si < position
            text << "#{src[si]} <br>"
            si += 1
            di += 1
          end
          si += elements.length
          elements.each do |l|
            text << "<del class=deleted>#{l.escapeHTML}</del>"
          end
        when :+
          while di < position
            text << "#{src[si]} <br>"
            si += 1
            di += 1
          end
          di += elements.length
          elements.each do |l|
            text << "<ins class=added>#{l.escapeHTML}</ins>"
          end
        end
      end
      while si < src.length
        text << "#{src[si]} <br>"
        si += 1
      end
      text
    end

    def to_s 
      @references = @visitor.references
      begin
        @visitor.visit(@tokens).gsub(/<\/?body>/, "")
      rescue Exception
        tree = RD::RDTree.new("=begin\n==Error! Please edit this page again.\n#{($!.backtrace.join("\n")).escapeHTML}" + "\n=end\n")
        @visitor.visit(tree).gsub(/<\/?body>/, "")
      end
    end

    def references
      @references.uniq
    end    

    def toc
      s = "<ul>\n"
      lv = 1
      @visitor.toc.each do |h|
        if h['level'] > lv
          s << ( "<ul>\n" * ( h['level'] - lv ) )
          lv = h['level']
        elsif h['level'] < lv
          s << ( "</ul>\n" * ( lv - h['level'] ) )
          lv = h['level']
        end
        s << %Q!<li><a href="##{h['index']}">#{h['title'].escapeHTML}</a>\n!
      end
      s << ("</ul>\n" * lv)
    end
  end
end
