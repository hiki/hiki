# parser.rb for Hiki/RD+
#
# Copyright (C) 2003 Masao Mutoh <mutoh@highway.ne.jp>
#
# You can redistribute it and/or modify it under the terms of
# the Ruby's licence.

require 'rd/rdfmt'
require 'cgi'

module Hiki
  class Parser_rd
    def initialize( conf )
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
