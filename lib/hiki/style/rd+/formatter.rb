# formatter.rb for Hiki/RD+
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

require "hiki/util"
require "hiki/formatter"
require "hiki/style/rd+/rd2html.rb"

module Hiki
  module Formatter
    class RD < Base
      Formatter.register(:rd, self)

      include Hiki::Util

      def initialize(s, db, plugin, conf, suffix = "l")
        @tokens     = s
        @db         = db
        @plugin     = plugin
        @conf       = conf
        @visitor = Hiki::RD2HTMLVisitor.new(@plugin, @db, @conf)
      end

      def to_s
        @references = @visitor.references
        begin
          @visitor.visit(@tokens).gsub(/<\/?body>/, "")
        rescue Exception
          tree = RD::RDTree.new("=begin\n==Error! Please edit this page again.\n#{h($!.backtrace.join("\n"))}" + "\n=end\n")
          @visitor.visit(tree).gsub(/<\/?body>/, "")
        end
      end

      def references
        @references.uniq
      end

      def toc
        s = "<ul>\n"
        lv = 1
        @visitor.toc.each do |hash|
          if hash["level"] > lv
            s << ("<ul>\n" * (hash["level"] - lv))
            lv = hash["level"]
          elsif hash["level"] < lv
            s << ("</ul>\n" * (lv - hash["level"]))
            lv = hash["level"]
          end
          s << %Q!<li><a href="##{hash['index']}">#{h(hash['title'])}</a>\n!
        end
        s << ("</ul>\n" * lv)
      end
    end
  end
end
