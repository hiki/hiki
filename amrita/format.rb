require "amrita/node"
require "amrita/tag"

module Amrita

  if RUBY_PLATFORM =~ /win/
    NL = "\r\n"
  else
    NL = "\n"
  end
  
  # This module provide methods for avoid XSS vulnerability
  # taken from IPA home page(Japanese)
  # http://www.ipa.go.jp/security/awareness/vendor/programming/a01_02.html
  module Sanitizer
    NAMECHAR = '[-\w\d\.:]'
    NAME = "([\\w:]#{NAMECHAR}*)"
    NOT_REFERENCE = "(?!#{NAME};|&#\\d+;|&#x[0-9a-fA-F]+;)" # borrowed from rexml
    AMP_WITHOUT_REFRENCE = /&#{NOT_REFERENCE}/
    # escape &<>
    def sanitize_text(text)
      s = text.dup
      s.gsub!(AMP_WITHOUT_REFRENCE, '&amp;')
      s.gsub!("<", '&lt;')
      s.gsub!(">", '&gt;')
      s
    end

    # escape &<>"'
    def sanitize_attribute_value(text)
      s = text.dup
      s.gsub!(AMP_WITHOUT_REFRENCE, '&amp;')
      s.gsub!("<", '&lt;')
      s.gsub!(">", '&gt;')
      s.gsub!('"', '&quot;')
      s.gsub!("'", '&#39;')
      s
    end

    DefaultAllowedScheme = {
      'http' => true,
      'https' => true,
      'ftp' => true,
      'mailto' => true,
    }

    #UrlInvalidChar = Regexp.new(%q|[^;/?:@&=+$,A-Za-z0-9\-_.!~*'()%]|)
    UrlInvalidChar = Regexp.new(%q|[^;/?:@&=+$,A-Za-z0-9\-_.!~*'()%#]|) #'

    # +sanitize_url+ accepts only these characters 
    #     --- http://www.ietf.org/rfc/rfc2396.txt ---
    #     uric = reserved | unreserved | escaped
    #     reserved = ";" | "/" | "?" | ":" | "@" | "&" | "=" | "+" | "$" | ","
    #     unreserved = alphanum | mark
    #     mark = "-" | "_" | "." | "!" | "~" | "*" | "'" | "(" | ")"
    #     escaped = "%" hex hex
    # 
    # +sanitize_url+ accepts only schems specified by +allowd_scheme+
    #
    # The default is http: https: ftp: mailt:

    def  sanitize_url(text, allowd_scheme = DefaultAllowedScheme)
      # return nil if text has characters not allowd for URL

      return nil if text =~ UrlInvalidChar

      # return '' if text has an unknown scheme
      # --- http://www.ietf.org/rfc/rfc2396.txt ---
      # scheme = alpha *( alpha | digit | "+" | "-" | "." )

      if text =~ %r|^([A-Za-z][A-Za-z0-9+\-.]*):| 
        return nil unless allowd_scheme[$1]
      end
  
      # escape HTML
      # special = "&" | "<" | ">" | '"' | "'"
      # But I checked  "<" | ">" | '"' before.
      s = text.dup
      #s.gsub!("&", '&amp;')
      s.gsub!("'", '&#39;')

      s
    end

    module_function :sanitize_text, :sanitize_attribute_value, :sanitize_url
  end
end

class String
  def amrita_sanitize
    Amrita::Sanitizer::sanitize_text(self)
  end

  def amrita_sanitize_as_attribute
    Amrita::Sanitizer::sanitize_attribute_value(self)
  end

  def amrita_sanitize_as_url
    Amrita::Sanitizer::sanitize_url(self)
  end
end

module Amrita

  # this is a String that amrita dosen't sanitize.
  # If you don't sanitize or sanitize yourself,
  # pass SanitizedString.new(x) as model data.
  class SanitizedString < String
    def SanitizedString::[](s)
      new(s)
    end

    def amrita_sanitize
      self
    end

    def amrita_sanitize_as_attribute
      self
    end

    def amrita_sanitize_as_url
      self
    end

    def to_s
      self
    end
  end

  #  A Formatter object prints a Node object as HTML text.
  class Formatter
    include Amrita

    attr_reader :stream #:nodoc:

    # If set, text will be escaped by Sanitizer#sanitize_text
    # Default is true.
    attr_accessor :escape

    # If set, single tag like <tt><hr></tt> will be printed as <tt><hr /></tt>
    # Default is false
    attr_accessor :asxml
    
    # If set, <tt><span></tt> with no attribute will be deleted.
    # Default is true
    attr_accessor :delete_span

    # If set, the spaces and new-lines in text will be compacted.
    # Default is false
    attr_accessor :compact_space

    # stream is any object that has << method.
    # All output is done by << method.
    def initialize(stream="", tagdict=DefaultHtmlTagInfo, &element_filter)
      @stream = stream
      @tagdict = tagdict
      @escape = true
      @asxml = false
      @delete_span = true
      @sanitized = false
      @compact_space = false
      @element_filter = element_filter
    end

    # Format a Node object.
    #
    # If +stream+ is given, the output is changed to it in this method.
    def format(node, stream=nil)
      node = Node::to_node(node)
      with_stream(stream) do
        node.format(self)
      end
    end

    def with_stream(stream, &block) #:nodoc:
      if stream
        save = @stream 
        @stream = stream
        begin
          yield
        ensure
          @stream = save
        end
        stream
      else
        yield
        @stream
      end
    end

    def put(t) #:nodoc:
      @stream << t
    end

    def <<(x) #:nodoc:
      case x
      when Node
        format(x)
      else
        @stream << x.to_s
      end
      self
    end

    def format_attrs(attrarray, taginfo=nil) #:nodoc:
      return nil if attrarray.size == 0
      array = attrarray.collect do |a|
        flag = taginfo ? taginfo.url_attr?(a.key) : false
        format_attr(a, flag)
      end
      array.join(" ")
    end

    def format_attr_default(a, flag) #:nodoc:
      attrval = a.value
      if attrval then
        if flag
          attrval = attrval.to_s.amrita_sanitize_as_url
        else
          attrval = attrval.to_s.amrita_sanitize_as_attribute
        end
        %Q'#{a.key}="#{attrval}"'
      else
        %Q'#{a.key}'
      end
    end
    alias format_attr format_attr_default

    # set replacing attribute.
    #
    #      f.set_attr_filter(:__id=>:id)
    #
    # <p __id="x"> is printed as <p id="x">
    def set_attr_filter(hash)
      src = [ "def self.format_attr(a, flag)" ]
      src << "case a.key"
      hash.each do |key, val|
        src << %Q[ when "#{key}" ; format_attr_default(Attr.new(:#{val}, a.value), flag)]
      end
      src << "else; format_attr_default(a, flag)"
      src << "end"
      src << "end"
      src << ""
      #puts src

      eval src.join("\n")
    rescue SctiptError, NameError
      puts src
    end

    def format_start_tag(e) #:nodoc:
      e = @element_filter.call(e) if @element_filter
      taginfo = @tagdict.get_tag_info(e.tagname_symbol)
      a = format_attrs(e.attrs, taginfo)
      if a
        %Q[<#{e.tagname} #{a}>]
      else
        %Q[<#{e.tagname}>]
      end
    end

    def format_end_tag(e) #:nodoc:
      %Q[</#{e.tagname}>]
    end

    def format_single_tag(e) #:nodoc:
      e = @element_filter.call(e) if @element_filter
      a = format_element_attrs(e)
      if asxml
        if a
          %Q[<#{e.tagname} #{a} />]
        else
          %Q[<#{e.tagname} />]
        end
      else
        if a
          %Q[<#{e.tagname} #{a}>]
        else
          %Q[<#{e.tagname}>]
        end
      end
    end

    def format_text(text) #:nodoc:
      text = text.to_s.amrita_sanitize if @escape
      text = text.gsub(%r[\s+]m, ' ') if @compact_space 
      @stream << text
      text
    end

    def can_be_single?(element) #:nodoc:
      taginfo_of_element(element).can_be_empty
    end

    def format_attr_of_element(attr, element)
      taginfo = taginfo_of_element(element)
      format_attr(attr, taginfo && taginfo.url_attr?(attr.key))
    end

    def format_element_attrs(element)
      format_attrs(element.attrs, taginfo_of_element(element))
    end

    def taginfo_of_element(element)
      @tagdict.get_tag_info(element.tagname_symbol)
    end
  end

  # This Formatter print out template with no change.
  class AsIsFormatter < Formatter
    def format_element(element, stream=nil, &block) #:nodoc:
      with_stream(stream) do
        if element.no_child? and can_be_single?(element)
          @stream << format_single_tag(element)
        else
          @stream <<  format_start_tag(element)
          if block_given?
            yield
          else
            element.body.format(self)
          end
          @stream <<  format_end_tag(element)
        end
      end
    end

    def new_line #:nodoc:
      @stream << NL
    end
  end

  # This Formatter compact spaces and delete new line.
  #
  class SingleLineFormatter < Formatter
    def initialize(stream="", tagdict=DefaultHtmlTagInfo) #:nodoc:
      super(stream)
      @compact_space = true
    end

    def format_element(element, stream=nil, &block) #:nodoc:
      with_stream(stream) do
        if element.no_child? and can_be_single?(element)
          @stream << format_single_tag(element)
        else
          @stream <<  format_start_tag(element)
          if block_given?
            yield
          else
            element.body.format(self)
          end
          @stream <<  format_end_tag(element)
        end
      end
    end
  end

  class PrettyPrintFormatter < Formatter
    attr_accessor :offset

    def initialize(stream="", tagdict=DefaultHtmlTagInfo) #:nodoc:
      super(stream)
      @tagdict = tagdict
      @level = 0
      @offset = 2
      @compact_space = true
      @first_of_line = true
    end

    def format(node, stream=nil) #:nodoc:
      with_stream(stream) do
        super
        @stream << NL
      end
    end

    def format_element(element, stream=nil, &block) #:nodoc:
      with_stream(stream) do
        body = element.body 
        pptype = @tagdict.get_tag_info(element.tagname_symbol).pptype
        unless element.no_child? and can_be_single?(element)
          first = format_start_tag(element)
          last = format_end_tag(element)

          prettyprint(pptype, first, last) do
            if block_given?
              yield
            else
              body.format(self)
            end
          end

        else
          s = format_single_tag(element)
          put(s)
          new_line unless pptype == 3
        end
      end
    end

    def prettyprint(tagtype, first, last, &block) #:nodoc:
      case tagtype
      when 1
        prettyprint1(first, last, &block)
      when 2
        prettyprint2(first, last, &block)
      when 3
        prettyprint3(first, last, &block)
      else
        prettyprint3(first, last, &block)
      end
    end

    def prettyprint1(first, last, &block) #:nodoc:
      new_line
      put(first)
      level_up
      new_line
      yield
      new_line
      level_down
      put(last)
      new_line
    end

    def prettyprint2(first, last, &block) #:nodoc:
      new_line
      put(first)
      yield
      put(last)
      new_line
    end

    def prettyprint3(first, last, &block) #:nodoc:
      put(first)
      yield
      put(last)
    end

    def level_up #:nodoc:
      @level = @level + 1
    end

    def level_down #:nodoc:
      @level = @level - 1
    end

    def put(t) #:nodoc:
      return unless t.size > 0
      t = t.gsub(/\s+/m, " ") if @compact_space
      if @first_of_line
        @stream << NL
        @stream << " " * (@offset * @level) if @offset
        @first_of_line = false 
      end
      @stream << t
    end

    def new_line #:nodoc:
      @first_of_line = true
    end
  end

  class PreFormatter
    attr_reader :formatter, :expand_attr
    def initialize(formatter, expand_attr=false)
      @formatter = formatter
      @expand_attr = expand_attr
      @result_str = ""
      @result_array = []
    end

    def pre_format(node)
      @formatter.with_stream(self) do
        node.pre_format1(self)
      end
    end

    def <<(x)
      case x
      when Element
        @result_array << SanitizedString[@result_str] unless @result_str == ""
        @result_array << x
        @result_str = ""
      when String
        @result_str << x
      when NodeArray
        x.array.each do |n|
          n.pre_format1(self)
        end
      when Node
        @formatter.format(x)
      else
        @result_str << x.to_s
      end
      self
    end

    def result
      @result_array << SanitizedString[@result_str] unless @result_str == ""
      case @result_array.size
      when 0
        Null
      when 1
        @result_array[0]
      else
        @result_array
      end
    end

    def result_as_top
      Node::to_node(result)
    end
  end

  module Node
    def to_s
      ret = ""
      SingleLineFormatter.new(ret).format(self)
      ret
    end

    # converts an Element without +id+ to TextElement to make
    # tree low for performance.
    # 
    # A pre-formatted Node tree will be expanded faster than
    # original. But, it produces the same output .
    def pre_format(formatter, expand_attr=false)
      raise "pre_format dose not suport pretty-print" if formatter.kind_of?(PrettyPrintFormatter)
      prf = PreFormatter.new(formatter, expand_attr)
      prf.pre_format(self)
      prf
    end

    def pre_format1(prf)
      prf << self
    end
  end

  class NullNode
    def format(f)
    end

    def pre_format1(prf)
    end
  end

  class Element
    def format(f)
      if f.delete_span and tagname_symbol == :span and attrs.size == 0 
        return body.format(f)
      else
        f.format_element(self)
      end
    end

    def pre_format1(prf)
      f = prf.formatter
      if hid or (prf.expand_attr and has_expandable_attr?)
        prf << clone do
          body.pre_format(f).result
        end
      else
        f.format_element(self) do
          body.pre_format1(prf)
        end
      end
    end
  end

  class TextElement
    def format(f)
      f.format_text(@text)
    end
  end

  class NodeArray
    def format(f)
      @array.each { |n| n.format(f) }
    end

    def pre_format1(prf)
      @array.each do |n|
        n.pre_format1(prf)
      end
    end
  end

  class SpecialElement
    def format(f)
      f.put("<#{@tag}")
      f.put(@body)
      f.put("#{etag}>")
    end
  end

  class FormatterNode #:nodoc:
    include Node
    def initialize(&block)
      init_body(&block)
    end

    def change_formatter(formatter, &block)
      # subclass responsibility
    end

    def format(formatter)
      change_formatter(formatter) do
        body.format(formatter)
      end
    end

    def pre_format1(pre_formatter)
      change_formatter(pre_formatter.formatter) do
        body.pre_format1(pre_formatter)
      end
    end

    def to_ruby
      "#{type}.new { #{body_to_ruby} }"
    end

    def body_to_ruby
      if @body
        @body.to_ruby 
      else
        ""
      end
    end
  end

  class Escape < FormatterNode #:nodoc:
    def initialize(escape=true, &block)
      @escape = escape
      super(&block)
    end

    def clone(&block)
      if block_given?
        Escape.new(@escape, &block) 
      else
        Escape.new(@escape) { @body.clone }
      end
    end

    def change_formatter(f)
      save = f.escape
      f.escape = @escape
      yield
    ensure
      f.escape = save
    end

    def to_ruby
      %Q[#{type}.new(#{@sanitize_text})] + body_to_ruby
    end
  end

  class CompactSpace < FormatterNode #:nodoc:
    def initialize(compact_space=true, &block)
      @compact_space = compact_space
      super(&block)
    end

    def clone(&block)
      if block_given?
        CompactSpace.new(@compact_space, &block) 
      else
        CompactSpace.new(@compact_space) { @body.clone }
      end
    end

    def change_formatter(f)
      save = f.compact_space
      f.compact_space= @compact_space
      yield
    ensure
      f.compact_space = save
    end
  end

  # format a Node object given as +block+ in
  # single line format.
  #
  # If +data+ was given, +expand+ will be called before
  # formatting
  def format_inline(data=true, &block)
    node = Node::to_node(yield)
    f = SingleLineFormatter.new
    f.format(node.expand1(data))
  end
  module_function :format_inline

  # pretty print a Node object given as +block+
  #
  # If +data+ was given, +expand+ will be called before
  # formatting
  #
  def format_pretty(data=true, &block)
    node = Node::to_node(yield)
    f = PrettyPrintFormatter.new
    f.format(node.expand1(data))
  end
  module_function :format_pretty

  # Usually the <> character in text will be escaped.
  #
  #     tmpl = TemplateText.new "<p id=x></p>"
  #     tmpl.expand(STDOUT, {:x => "<tag>"}) # => <p>&lt;tag&gt;</p>
  #
  # If the text was wrapped by this method, 
  # it will no be escaped.
  #
  #     tmpl.expand(STDOUT, {:x => noescape {"<tag>"}}) # =>  <p><tag></p>

  def noescape(&block) 
    Escape.new(false, &block)
  end
  module_function :noescape

  # If the text was wrapped by this method,
  # spaces in it will be keeped.
  def pre(*attrs, &block) 
    Element.new(:pre, *attrs) { CompactSpace.new(false, &block) }
  end
  module_function :pre
end


