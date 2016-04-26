require "hiki/registry"

module Hiki
  module Style
  end
  module Formatter
    REGISTRY = Registry.new(:formatter)
    extend Registry::ClassMethods
  end
  module Parser
    REGISTRY = Registry.new(:parser)
    extend Registry::ClassMethods
  end
end

require "hiki/style/default/parser"
require "hiki/style/default/formatter"
require "hiki/style/rd+/parser"
require "hiki/style/rd+/formatter"
require "hiki/style/math/parser"
require "hiki/style/math/formatter"
