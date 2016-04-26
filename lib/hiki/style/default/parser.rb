# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

require "hikidoc"

module Hiki
  module Parser
    class Default
      Parser.register(:default, self)

      class << self
        def heading(str, level = 1)
          "!" * level + str
        end

        def link(link_str, str = nil)
          str ? "[[#{str}|#{link_str}]]" : "[[#{link_str}]]"
        end

        def blockquote(str)
          str.split(/\n/).collect{|s| %Q|""#{s}\n|}.join
        end
      end

      def initialize(conf)
        @use_wiki_name = conf.use_wikiname
      end

      def parse(s, top_level = 2)
        HikiDoc.to_html(s, level: top_level,
                        use_wiki_name: @use_wiki_name)
      end
    end
  end
end
