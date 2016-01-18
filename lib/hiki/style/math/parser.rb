
require "hiki/style/default/parser"

module Hiki
  module Parser
    class Math < Default
      Hiki::Config::PARSER_REGISTRY[:math] =  self
    end
  end
end
