
class String #:nodoc:
  # to treat Symbol and String equally
  def id2name
    self
  end

  # clone and freeze a String to share it
  def frozen_copy
    if frozen?
      self
    else
      dup.freeze
    end
  end
end

class Symbol #:nodoc:
  # to treat Symbol and String equally
  def intern
    self
  end
end

module Amrita 

  # represents a +key+ +value+ pair in HTML Element
  class Attr
    attr_accessor :value

    def initialize(key, value=nil)
      @key = key.intern
      case value
      when nil
        @value = nil
      when String
        @value = value.frozen_copy
      else
        @value = value.to_s.freeze 
      end
    end 

    def clone
      Attr.new(@key, @value)
    end

    def ==(x)
      return false unless x.kind_of?(Attr)
      x.key_symbol == @key and x.value == @value
    end

    # return +key+ as String    
    def key
      @key.id2name
    end

    # return +key+ as Symbol
    def key_symbol
      @key
    end

    def to_ruby
      if key =~ /^\w+$/
        if value
          "a(:#{key}, \"#{value}\")"
        else
          "a(:#{key})"
        end
      else
        if value
          "a(\"#{key}\", \"#{value}\")"
        else
          "a(\"#{key}\")"
        end
      end
    end
  end

  # Array of Attr s.
  # It can hold +body+ part for using as a model data for Node#expand.
  # Amrita#a() method is a shortcut for Attr.new
  class AttrArray
    include Enumerable

    # If you call a() { ... }, block yields to +body+
    attr_reader :array, :body

    # internal use only, never touch it!
    # 
    # true if this instance is shared by two or more elements
    attr_accessor :shared

    # Don't use AttrArray.new use a() instead
    def initialize(*attrs, &block)
      @array = []
      @shared = false
      attrs.each do |a|
        case a
        when Array, AttrArray
          a.each do |aa|
            self << aa
          end
        when Hash
          attrs[0].each do |k, v|
            self << Attr.new(k, v)
          end
        else
          self << a
        end
      end

      if block_given?
        @body = yield 
      else
        @body = Null
      end
    end

    # AttrArray#== concerns the order of Attr
    def ==(x)
      return true if id == x.id
      return false unless x.kind_of?(AttrArray)
      each_with_index do |a, n|
        return false unless a == x[n]
      end
      true
    end

    def inspect
      to_ruby
    end

    # add an Attr
    def <<(a)
      raise "must be Attr not #{a.class}" unless a.kind_of?(Attr)
      @array << a
    end

    def clear
      @array.clear
    end

    def [](index)
      @array[index]
    end

    def []=(index, val)
      @array[index] = val
      val
    end

    # iterate on each Attr
    def each(&block)
      @array.each(&block)
    end

    def size
      @array.size
    end

    def to_ruby
      ret = "a(" + @array.collect {|a| ":#{a.key}, #{a.value}"}.join(", ") + ")"
      case @body
      when nil, Null
      when Node
        ret += body.to_ruby
      else
        ret += body.inspect
      end
      ret
    end
  end

  # Base module for HTML elements
  module Node
    include Enumerable

    # set the +block+ 's result to +body+
    def init_body(&block)
      if block_given?
        @body = to_node(yield)
      else
        @body = Null
      end
    end

    # a Node has NullNode as body before init_body was called.
    def body
      if defined? @body
        @body
      else
        Null
      end
    end

    # test if it has any children
    def no_child?
      body.kind_of?(NullNode)
    end

    # return an Array of child Node or an empty Array if it does not have a body
    def children
      if no_child?
        []
      else
        [ body ]
      end
    end

    # generate a Node object 
    def to_node(n)
      case n
      when nil, false
        Null
      when Node
        n
      when Array
        case n.size()
        when 0
          Null
        when 1
          to_node(n[0])
        else
          NodeArray.new(*n)
        end
      else
        TextElement.new(n.to_s) 
      end
    end
    module_function :to_node

    def hid 
      nil
    end

    def inspect
      to_ruby
    end

    # Node can be added and they become NodeArray
    def +(node)
      NodeArray.new(self, to_node(node))
    end

    # Copy a Node n times and generate NodeArray
    def *(n)
      raise "can't #{self.class} * #{n}(#{n.class})" unless n.kind_of?(Integer)
      a = (0...n).collect { |i| self }
      NodeArray.new(*a)
    end

    # iterate on self and children
    def each_node(&block)
      c = children # save children before yield
      yield(self)
      c.each do |n|
        n.each_node(&block)
      end
    end

    # iterate on child Elements
    def each_element(&block)
      each_node do |node|
        yield(node) if node.kind_of?(Element)
      end
    end
    alias each each_element

    # iterate on child Elements with id.
    # If recursive == false, don't go to children of an Element with id.
    def each_element_with_id(recursive=false, &block)
      children.each do |node|
        node.each_element_with_id(recursive, &block)
      end
    end

    # test if an Element or children has any id
    def has_id_element?
      each_node do |n|
        next unless n.kind_of?(Element)
        next unless n.hid
        return true
      end
      false
    end
  end

  # singleton and immutable object
  class NullNode #:nodoc:
    include Node

    private_class_method :new

    # NullNode::new can not be used. Use this instead.
    def NullNode.instance
      new
    end

    def ==(x)
      x.kind_of?(NullNode)
    end

    # Share the only instance because it's a singleton and immutable object.
    def clone
      self
    end

    def +(node)
      node
    end

    def to_ruby
      "Amrita::Null"
    end

    # NullNode has no children
    def children
      []
    end
  end
  Null = NullNode.instance

  # represents HTML element
  class Element
    include Node
    
    # return attributes as AttrArray
    #
    # CAUTION! never edit result of this method. use []= instead.
    # because it may be shared by other Elements.
    attr_reader :attrs

    # CAUTION! internal use only
    attr_reader :attrs_hash, :hide_hid

    # return body
    attr_reader :body

    # Don't use Element.new. Use Amrita#e instead.
    def initialize(tagname_or_element, *a, &block)
      case tagname_or_element
      when Element
        @tagname = tagname_or_element.tagname_symbol
        @attrs = tagname_or_element.attrs
        @attrs.shared = true
        @attrs_hash = tagname_or_element.attrs_hash
        @hide_hid = tagname_or_element.hide_hid
        if block_given?
          init_body(&block)
        else
          @body = tagname_or_element.body.clone
        end
      when Symbol, String
        set_tag(tagname_or_element)
        @attrs = AttrArray.new
        @attrs_hash = {}
        @hide_hid = false
        if a.size() == 1 and a.kind_of?(AttrArray)
          @attrs = a
          @attrs.shared = true
          @attrs.each do |a|
            @attrs_hash[a.key_symbol] = a
          end
        else
          a.each { |aa| put_attr(aa) }
        end
        if block_given?
          init_body(&block)
        else
          @body = Null
        end
      end
    end

    # test if tagname and attributes and body are equal to self.
    # doesn't concern the order of attributes
    def ==(x)
      return false unless x.kind_of?(Element)
      return true if x.id == id
      return false unless x.tagname_symbol == @tagname
      return false unless x.attrs.size == @attrs.size
      @attrs.each do |a|
        return false unless x[a.key] == a.value
      end
      return false unless x.body == @body
      true
    end

    def set_tag(tagname)
      if tagname
        @tagname = tagname.intern 
      else
        @tagname = nil
      end
    end

    def clone(&block)
      Element.new(self, &block)
    end

    # return Tag as String
    def tagname
      @tagname.id2name
    end

    # return Tag as Symbol
    def tagname_symbol
      @tagname
    end

    # return id=... attribule value. It can be hide by +hide_hid!
    def hid
      if @hide_hid
        nil
      else
        self[:id] or self[:ID]
      end
    end

    # hide hid for internal use (expand).
    def hide_hid!
      @hide_hid = true
    end

    def tagclass
      self[:class]
    end

    # set attribule.
    def put_attr(a)
      copy_on_write if @attrs.shared
      case a
      when Attr
        if @attrs_hash[a.key_symbol] 
          self[a.key_symbol] = a.value
        else
          a = a.clone
          @attrs << a
          @attrs_hash[a.key_symbol] = a
        end
      when AttrArray
        a.each do |aa|
          put_attr(aa)
        end
      when Hash
        a.each do |k, v|
          put_attr(Attr.new(k, v))
        end
      else
        raise " << not a Attr but a #{a.class}" unless a.kind_of?(Attr)
      end
    end

    def <<(a, &block)
      put_attr(a)
      init_body(&block) if block_given?
      self
    end

    # test if it has attribule for +key+
    def include_attr?(key)
      @attrs_hash.include?(key.intern)
    end

    # return attribule value for +key+
    def [](key)
      a = @attrs_hash[key.intern]
      if a
        a.value
      else
        nil
      end
    end

    # set attribule. delete it if +value+ is +nil+
    def []=(key, value)
      copy_on_write if @attrs.shared
      key = key.intern 
      a = @attrs_hash[key]
      if a
        if value
          a.value = value
        else
          delete_attr!(key)
        end
      else
        put_attr(Attr.new(key,value)) if value
      end
      value
    end

    # delete attribute of +key+
    def delete_attr!(key)
      copy_on_write if @attrs.shared
      key = key.intern 
      old_attrs = @attrs
      @attrs = AttrArray.new
      @attrs_hash = {}
      old_attrs.each do |a|
        put_attr(a) if a.key_symbol != key
      end
    end
    
    def to_ruby
      ret = "e(:#{tagname}"
      if attrs.size > 0
        ret << ","
        ret << attrs.collect { |a| a.to_ruby}.join(",")
      end
      ret << ") "
      ret << "{ #{body.to_ruby} }" if body and not body.kind_of?(NullNode)
      ret
    end

    def each_element_with_id(recursive=false, &block)
      if hid
        yield(self)
        super if recursive
      else
        super
      end
    end

    # set the +text+ to body of this Element.
    def set_text(text)
      @body = TextElement.new(text)
    end

    private
    def copy_on_write
      old_attrs = @attrs
      @attrs = AttrArray.new
      @attrs_hash = {}
      old_attrs.each do |a|
        put_attr(a)
      end
    end
  end

  # immutable object
  class TextElement #:nodoc:
    include Node

    def initialize(text=nil)
      case text
      when nil
        @text = ""
      when String
        @text = text.frozen_copy
      when TextElement
        @text = x.to_s
      else
        @text = value.to_s.freeze 
      end
    end

    def clone
      self # immutable object can be shared always
    end

    def ==(x)
      case x
      when String
        to_s == x
      when TextElement
        to_s == x.to_s
      else
        false
      end
    end

    def to_ruby
      @text.inspect
    end

    def to_s
      @text
    end
  end

  # represents an Array of Node. It is a Node also.
  class NodeArray
    include Node
    attr_reader :array
    def initialize(*elements)
      if elements.size() == 1 and elements[0].kind_of?(NodeArray)
        a = elements[0]
        @array = a.array.collect { |n| n.clone }
      else
        @array = elements.collect do |a|
          #raise "can't be a parent of me!" if a.id == self.id # no recusive check because it costs too much
          to_node(a)
        end
      end
    end

    def ==(x)
      return false unless x.kind_of?(NodeArray)
      case x
      when NodeArray, Array
        return false unless x.size() == @array.size()
        @array.each_with_index do |n, i|
          return false unless n == x[i]
        end
        true
      else
        false
      end
    end

    def size()
      @array.size()
    end

    def [](index)
      @array[index]
    end

    def no_child?
      @array.empty?
    end

    def clone
      NodeArray.new(self)
    end

    def children
      @array
    end

    def +(node)
      ret = clone
      ret << node
      ret
    end

    def <<(node)
      raise "can't be a parent of me!" if node == self
      @array << to_node(node)
      self
    end

    def to_ruby
      "[ " + @array.collect {|e| e.to_ruby}.join(", ") + " ]"
    end
  end

  # represents a special tag like a comment.
  class SpecialElement #:nodoc:
    attr_reader :tag, :body
    attr_reader :fname, :lno
    include Node
    def initialize(tag, body, fname=nil, lno=nil)
      @tag = tag
      @body = body.dup.freeze
      @fname = fname
      @lno = lno
    end

    def clone
      SpecialElement.new(@tag, @body, @fname, @lno)
    end

    def children
      []
    end

    # end tag
    def etag
      case @tag 
      when '%=', '%'
        '%'
      when '!'
        ''
      when '!--'
        '--'
      when '?'
        '?'
      else
        @tag
      end
    end


    def to_ruby
      %Q(special_tag(#{@tag.dump}, #{@body.dump}) )
    end
  end
  
  # generate Element object
  #
  
  # [e(:hr)] <hr>
  # [e(:img src="a.png")]  <img src="a.png">
  # [e(:p) { "text" }]  <p>text</p>
  # [e(:span :class=>"fotter") { "bye" } ] <span class="fotter">bye</span>
  
  def e(tagname, *attrs, &block)
    Element.new(tagname, *attrs, &block)
  end
  alias element e
  module_function :e
  module_function :element

  # generate AttrArray object
  def a(*x, &block)
    case x.size
    when 1
      x = x[0]
      case x
        when Hash
        when String,Symbol
        x = Attr.new(x)
        when Attr
        else
        raise(TypeError, "Not Attr,String or Symbol: #{x}")
      end
      AttrArray.new(x, &block)
    when 0
      AttrArray.new([], &block)
    else
      a = (0...x.size/2).collect do |i|
        Attr.new(x[i*2], x[i*2+1])
      end
      AttrArray.new(a, &block)
    end
  end
  alias attr a
  module_function :a
  module_function :attr

  def text(text) #:nodoc:
    TextElement.new(text)
  end
  module_function :text

  def link(href, klass = nil, &block) #:nodoc:
    element("a",&block) << attr(:href, href) 
  end
  module_function :link

  def special_tag(tag, body, fname=nil, lno=nil) #:nodoc:
    SpecialElement.new(tag, body, fname, lno)
  end
  module_function :special_tag

  def Amrita::append_features(klass) #:nodoc:
    super
    def klass::def_tag(tagname, *attrs_p)
      def_tag2(tagname, tagname, *attrs_p)
    end

    def klass::def_tag2(methodname, tagname, *attrs_p)
      methodname = methodname.id2name 
      tagname = tagname.id2name 
      attrs = attrs_p.collect { |a| a.id2name }

      if attrs.size > 0
        param = attrs.collect { |a| "#{a}=nil" }.join(", ")
        param += ",*args,&block"
        method_body = "  e(:#{tagname}, "
        method_body += attrs.collect { |a| "A(:#{a}, #{a})"}.join(", ")
        method_body += ", *args, &block)"
      else
        param = "*args, &block"
        method_body = "  e(:#{tagname}, *args, &block) "
      end
      a = "def #{methodname}(#{param}) \n#{method_body}\nend\n"
      #print a
      eval a
    end
  end
end
