
require "hiki/style/default/parser"

module Hiki
  module Parser
    class Math < Default
      Parser.register(:math, self)
    end
  end
end
