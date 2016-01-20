require 'hiki/registry'

module Hiki
  module Messages
    REGISTRY = Hiki::Registry.new(:messages)
  end
end

require 'hiki/messages/ja'
require 'hiki/messages/de'
require 'hiki/messages/en'
require 'hiki/messages/fr'
require 'hiki/messages/it'
