require 'rexml/document'
require 'amrita/template'
require 'amrita/xml'

module REXML
  class Element
    def amrita_expand_element(e, context)
      context.rexml2amrita(self)
     end
  end
end


module Amx
  include Amrita

  class Document < REXML::Document
    def template_href
      ret = "default.amx"
      each do |n|
        next unless n.kind_of?(REXML::Instruction)
        next unless n.target.downcase == "amx"
        if n.content =~ /(\w+)="(.*)"/ and $1 == "href"
          ret = $2
          break
        else
          raise "unknown instruction #{n.content}"
        end
      end
      ret
    end
  end

  class AmxContext < Amrita::ExpandContext
    def initialize(template)
      super()
      @template = template
    end

    def rexml2amrita(xml)
      @template.rexml2amrita(xml)
    end
  end


  class Template < Amrita::Template
    include ExpandByMember
    attr_reader :root, :doc
    def Template::[](f)
      path = case f
             when String 
               f
             when REXML::Document
               f.template_href
             else
               raise "unknown param #{f.type}"
             end
      
      doc = REXML::Document.new(REXML::File.new(path))
      root = doc.elements['amx']
      req = root.attributes['require']
      require(req) if req
      clsname = root.attributes['class']

      cls = if clsname
              eval clsname
            else
              Template
            end
      cls.new(path, doc)
    end

    def initialize(path, doc)
      super()
      @template_root = doc
      @path = path
      @xml = @asxml = true
      init_amx
    end

    def init_amx
      @template_root.elements.to_a("amx/method").each do |m|
        method_name = m.attributes['id'].to_s
        code = m.elements['method_body'].get_text.to_s
        define_method(method_name, code)
      end
    end

    def define_method(method_name, code)
      instance_eval <<-END
        def #{method_name}
          #{code}
        end
      END
    end

    def get_model
      self
    end 

    def setup_context
      context = AmxContext.new(self)
      context.delete_id = false if keep_id
      context
    end

    def expand(stream, doc)
      @doc = doc
      befor_expand
      super(stream, get_model)
      puts ""
    ensure
      @doc = nil
    end

    def befor_expand
    end

    def setup_template
      @template = rexml2amrita(@template_root.elements['amx/template'].elements)
    end

    def rexml2amrita(xml)
      case xml
      when REXML::Element
        h = {}
        xml.attributes.each do |k,v|
          h[k] = convert(v)
        end
        e(xml.name, h) {
          xml.collect do |x|
            rexml2amrita(x)
          end
        }
      when REXML::Elements
        ret = xml.collect do |x|
          rexml2amrita(x)
        end
        Node::to_node(ret)
      when REXML::Text
        TextElement.new convert(xml.to_s)
      when REXML::Instruction
        "REXML::Instruction here(PENDING)"
      else
        raise "can't convert #{xml.type}"
      end
    end
  end

end
