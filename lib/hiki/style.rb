require 'hiki/registry'

module Hiki
  module Style
  end
  module Formatter
    REGISTRY = Registry.new(:formatter)
  end
  module Parser
    REGISTRY = Registry.new(:parser)
  end
end

require 'hiki/style/default/parser'
require 'hiki/style/default/formatter'
require 'hiki/style/rd+/parser'
require 'hiki/style/rd+/formatter'
require 'hiki/style/math/parser'
require 'hiki/style/math/formatter'
