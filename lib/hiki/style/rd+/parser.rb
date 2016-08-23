# parser.rb for Hiki/RD+
#
# Copyright (C) 2003 Masao Mutoh <mutoh@highway.ne.jp>
#
# You can redistribute it and/or modify it under the terms of
# the Ruby's licence.

require "rd/rdfmt"
require "cgi"

module Hiki
  module Parser
    class RD
      Parser.register(:rd, self)

      class << self
        def heading(str, level = 1)
          "=" * level + str
        end

        def link(link_str, str = nil)
          require "uri"
          link_str = "URL:#{link_str}" if link_str.index(URI.regexp) == 0
          str ? "((<#{str}|#{link_str}>))" : "((<#{link_str}>))"
        end

        def blockquote(str)
          str # RD does not support blockquote.
        end
      end

      def initialize(conf)
      end

      def parse(s)
        begin
          RD::RDTree.new("=begin\n#{s}\n=end\n\n")
        rescue
          error = $!.message.gsub(/^/, "  ")
          i = 0
          s = "\n#{s}\n"
          src = s.split(/\n/).collect{|v| i += 1; "  %03d:   #{v.gsub('%', '%%')}" % [i]}.join("\n")
          begin
            RD::RDTree.new("=begin\n==Error! Please edit this page again.\n#{error}\n===Original document\n\n#{src}" + "\n=end\n")
          rescue
            RD::RDTree.new("=begin\n==Error! Please edit this page again.\n#{error}\n=end\n")
          end
        end
      end
    end
  end
end
