require "amrita/node"
require "rexml/document"
require "rexml/streamlistener"

module Amrita
  has_uconv = true
  begin
    require 'uconv'
  rescue LoadError
    has_uconv = false
  end
  if has_uconv 
    case $KCODE
    when "EUC"
      def convert(s)
        Uconv::u8toeuc(s)
      end
    when "SJIS"
      def convert(s)
        Uconv::u8tosjis(s)
      end
    else
      def convert(s)
        s
      end
    end
  else
    def convert(s)
      s
    end
  end

  class Listener
    include Amrita
    include REXML::StreamListener


    def initialize
      @stack = [ Null ]
    end

    def push(element)      
      @stack.unshift element
    end

    def pop
      @stack.shift
    end

    def top
     @stack.first
    end

    def result
      raise "can't happen @stack.size=#{@stack.size}" unless @stack.size == 1
      top
    end

    def tag_start(name, attrs)
      a = attrs.collect do |key, val|
        Attr.new(key, convert(val))
      end
      push e(name, *a)
      push Null
    end

    def tag_end(name)
      body = pop
      element = pop
      element.init_body { body }
      push(pop + element)
    end

    def text(text)
      push(pop + TextElement.new(convert(text)))
    end

    def xmldecl(version, encoding, standalone)
      text = %Q[xml version="#{version}"]
      text += %Q[ encoding="#{encoding}"] if encoding
      s = SpecialElement.new('?', text)
      push(pop + s)
    end

    def doctype(name, pub_sys, long_name, uri)
      s = SpecialElement.new('!',
                             %Q[DOCTYPE #{name} #{pub_sys} #{long_name} #{uri}])
      push(pop + s)
    end
  end

  module XMLParser
    def XMLParser.parse_text(text, fname="", lno=0, dummy=nil, &block)
      l = Listener.new(&block) 
      REXML::Document.parse_stream(text, l)
      l.result
    end

    def XMLParser.parse_file(fname, dummy=nil, &block)
      l = Listener.new(&block) 
      REXML::Document.parse_stream(REXML::File.new(fname), l)
      l.result
    end
  end
end
