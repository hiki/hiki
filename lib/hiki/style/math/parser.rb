
require "hiki/style/default/parser"

module Hiki
  module Parser
    class Math < Default
      Hiki::Parser::REGISTRY[:math] =  self
    end
  end
end
