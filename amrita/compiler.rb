require 'amrita/format'


class Object
  def amrita_generate_hint
    Amrita::HtmlCompiler::NoHint::Instance
  end

  def amrita_expand_and_format(node, context, formatter)
    formatter.format(node.expand1(self, context))
  end
end

class Hash
  def amrita_generate_hint
    children = {}
    each do |key, val|
      children[key] = val.amrita_generate_hint
    end
    Amrita::HtmlCompiler::HashData[children]
  end
end

class String
  def amrita_generate_hint
    Amrita::HtmlCompiler::ScalarData.new
  end
end

class Number
  def amrita_generate_hint
    Amrita::HtmlCompiler::ScalarData.new
  end
end

class Integer
  def amrita_generate_hint
    Amrita::HtmlCompiler::ScalarData.new
  end
end



class Array
  def amrita_generate_hint
    Amrita::HtmlCompiler::ArrayData.new(self[0].amrita_generate_hint)
  end
end

module Amrita
  module PartsTemplate
  end

  class MergeTemplate
  end

  class AttrArray
    def amrita_generate_hint
      if body
        Amrita::HtmlCompiler::AttrData[body.amrita_generate_hint]
      else
        Amrita::HtmlCompiler::AttrData.new
      end
    end
  end

  module Node
    def compile(compiler)
      compiler << to_s
    end

    def generate_hint_from_template
      hash = {}
      each_element_with_id do |e|
        hash[e.hid.intern] = HtmlCompiler::AnyData
      end
      HtmlCompiler::DictionaryHint.new(hash)
    end
  end

  class Element
    def compile(c)
      if hid =~ /^\w+$/
        c.compile_id_element(self) 
      else
        c.compile_var_attr(self) or
          c.put_static_element(self) do
          body.compile(c)
        end
      end
    end

    def expand_and_format(data, context, formatter)
      data.amrita_expand_and_format(self, context, formatter)
    end
  end

  class TextElement
    def compile(compiler)
      compiler.put_text @text
    end
  end

  class NodeArray
    def compile(compiler)
      children.each { |node| node.compile(compiler) }
    end
  end

  class Escape
    def compile(c)
      change_formatter(c.static_formatter) do
        vn = c.new_varname
        c.put_src "#{vn} = #{c.dynamic_formatter_var_name}.escape"
        c.put_src "#{c.dynamic_formatter_var_name}.escape = #{@escape}"
        c.put_src "begin"
        c.level_up do
          body.compile(c)
        end
        c.put_src "ensure"
        c.level_up do
          c.put_src "#{c.dynamic_formatter_var_name}.escape = #{vn}"
        end
        c.put_src "end"
      end
    end
  end


  module HtmlCompiler  #:nodoc:all
    class Hint #:nodoc:
      attr_accessor :varname

      def initialize
        @varname = nil
      end

      def new_data(compiler, subdataname)
        #raise "can't get data because no Hint given" if subdataname
        return self, varname
      end

      def compile(element, compiler)
        p self
        p element
        raise "not implemented"
      end

      def with_varname(new_varname = self.varname, &block)
        save = varname
        self.varname = new_varname
        yield
      ensure
        self.varname = save
      end
    end

#     class NoHint < Hint #:nodoc:
#       Instance = NoHint.new
#        def compile(e, c)
#          hid = e.hid
#          hid = hid.intern if hid
#          e = c.new_constant(e.to_ruby)
#          c.with_data(hid) do |get_data_src|
#            vn = c.new_varname
#            c.put_src "#{vn} = #{e}.expand1(#{get_data_src}, #{c.context_var_name})"
#            c._if("#{vn}.kind_of?(Element)") do 
#              c.put_dynamic_element(%Q[#{vn}])
#              c._else do
#                c.put_src "#{c.dynamic_formatter_var_name}.format(#{vn})"
#              end
#            end
#          end
#        end
#      end

     class NoHint < Hint #:nodoc:
       Instance = NoHint.new
       def compile(e, c)
         hid = e.hid
         hid = hid.intern if hid
         e = c.new_constant(e.to_ruby)
         c.with_data(hid) do |get_data_src|
           c.put_src "#{e}.expand_and_format(#{get_data_src}, #{c.context_var_name}, #{c.dynamic_formatter_var_name})"
         end
       end
     end

    class DictionaryHint < Hint  #:nodoc:
      attr_reader :hash
      def initialize(hash)
        super()
        raise "must be hash " unless hash.kind_of?(Hash)
        @hash = {}
        hash.each do |k, v|
          case v
          when Class
            @hash[k] = v.new
          else
            @hash[k] = v
          end
        end
      end

      def new_data(c, subdataname)
        @dataname = c.current_data.varname
        if subdataname
          next_data = (@hash[subdataname.intern] or NoHint::Instance)
          return next_data, "get_data_from_dictionary(#{@dataname}, :#{subdataname})"
        else
          return self, @dataname
        end
      end

      def compile(e, c)
        c.with_dictionary(c.current_data.varname) do
          c.put_static_element(e) do
            e.body.compile(c)
          end
        end
      end
    end

    class HashData < DictionaryHint  #:nodoc:
      def HashData::[](*p); new(*p) ;end

      def new_data(c, subdataname)
        dataname = c.current_data.varname
        if subdataname
          next_data = (@hash[subdataname.intern] or NoHint::Instance)
          return next_data, "#{dataname}[:#{subdataname}]"
        else
          return self, dataname
        end
      end
    end

    class MemberData < DictionaryHint  #:nodoc:
      def MemberData::[](*p); new(*p) ;end

      def new_data(c, subdataname)
        dataname = c.current_data.varname
        if subdataname
          next_data = (@hash[subdataname.intern] or NoHint::Instance)
          return next_data, "#{dataname}.#{subdataname}"
        else
          return self, dataname
        end
      end
    end

    class ArrayData < Hint #:nodoc:
      def ArrayData::[](*p); new(*p) ;end

      def initialize(subdata)
        super()
        case subdata
        when Class
          @subdata = subdata.new
        else
          @subdata = subdata
        end 
      end

      def new_data(c, subdataname)
        new_dataname = c.new_varname
        @subdata.varname = new_dataname
        return @subdata, varname
      end

      def compile(element, c)
        hid = element.hid.intern
        c.do_copy do
          c.with_data(hid) do |get_data_src|
            new_dataname = c.new_varname
            c._each(get_data_src) do |new_dataname|
              c.current_data.varname = new_dataname
              c.current_data.compile(element, c)
            end
          end
        end
      end
    end

    class ScalarData < Hint #:nodoc:
      def new_data(c, subdataname)
        #raise "can't get data because no Hint given" if subdataname
        return self, nil
      end

      def compile(e, c)
        c._if(varname) do
          c.put_static_element(e) do
            c.put_src("#{c.dynamic_formatter_var_name}.format_text(#{varname}.to_s) ")
          end
        end
      end
    end

    class ProcData < Hint #:nodoc:
      def new_data(c, subdataname)
        #raise "can't get data because no Hint given" if subdataname
        return self, nil
      end

      def compile(e, c)
        e = c.new_constant(e.to_ruby)
        c.put_dynamic_element(%Q[#{varname}.call(#{e}, #{c.context_var_name})])
      end
    end

    class AttrData < Hint #:nodoc:
      def AttrData::[](*p); new(*p) ;end
      def initialize(body=nil)
        super()
        @has_body = (body != nil)
        @body = (body or NoHint::Instance)
      end

      def new_data(c, subdataname)
        return @body, "#{varname}.body"
      end

      def compile(element, c)
        e = element.clone
        varname_for_e = c.new_varname
        ec = c.new_constant(e.clone{ nil }.to_ruby)
        c.put_src("#{varname_for_e} = #{ec}.clone")
        c._if("#{c.context_var_name}.delete_id") do 
          c.put_src "#{varname_for_e}.delete_attr!(:id)"
        end
        c.put_src "#{varname_for_e}.hide_hid!"
        c.put_src("#{varname}.each { |a| #{varname_for_e}[a.key_symbol] = a.value } ")
        c.put_dynamic_element(%Q[#{varname_for_e}]) do
          c.with_data do |a|
            if e.body.no_child? and @has_body
              c.put_src("#{c.dynamic_formatter_var_name}.format_text(#{varname}.body.to_s) ")
            else
              e.body.compile(c)
            end
          end
        end
      end
    end

    module RuntimeRoutines
      include Amrita
      def filter_nil_and_enum(data, &block)
        case data
        when nil, false
          # do nothing
        when true, String, Numeric, Proc
          yield(data)
        when Amrita::DictionaryData, Amrita::Node, Amrita::AttrArray
          yield(data)
        when Enumerable
          data.each do |d|
            filter_nil_and_enum(d, &block)
          end
        else
          yield(data)
        end
      end

      def get_data_from_dictionary(data, key)
        case data
        when Hash
          data[key]
        when ExpandByMember
          data.__send__(key)
        else
          #data.__send__(key)
          data.amrita_get_data(key, Null, DefaultContext)
          #raise "not a DictionaryData but #{data.class} for #{key}"
        end
      end
    end

    class Compiler  #:nodoc:
      include Amrita
      # Compiler
      attr_reader :static_formatter, :dynamic_formatter_var_name
      attr_reader :context_var_name

      attr_accessor :use_const_def, :delete_id, :expand_attr, :debug_compiler

      def initialize(static_formatter, dynamic_formatter_var_name="_formatter", 
                     context_var_name="_context", model_var_name="_data")
        @static_formatter = static_formatter
        @dynamic_formatter_var_name = dynamic_formatter_var_name
        @context_var_name = context_var_name
        @model_var_name = model_var_name

        @delete_id = true
        @expand_attr = false
        @symseq = 1

        @debug_compiler = false 
      end

      def init_src(hint)
        @constants = []
        @src = []
        @level = 1
        @buffer = ""
        flush_text
        hint = NoHint::Instance unless hint
        hint.varname = @model_var_name
        @hint_data_stack = [ hint ]
        @current_dictionary_varname = nil

        if @debug_compiler
          @offset = 2
          @use_const_def = false
        else
          @offset = 0
          @use_const_def = true
        end
      end

      def current_data
        @hint_data_stack[-1]
      end

      def new_varname
        @symseq += 1
        "__d#{@symseq}"
      end

      def new_constant(init_src, var_prefix="")
        if @use_const_def
          @constants << [init_src, var_prefix]
          constant_name(@constants.size-1, var_prefix)
        else
          init_src
        end
      end

      def constant_name(i, var_prefix)
        %Q[C_#{var_prefix}#{'%04d' % i}]
      end

      def const_def_src
        i = -1
        @constants.collect do |init_src, var_prefix|
          i += 1
          %Q[#{constant_name(i, var_prefix)} = #{init_src}]
        end
      end

      def with_data(subdataname=nil, &block)
        curr_data, get_data_src = current_data.new_data(self, subdataname)

        withdata_do = proc do
          @hint_data_stack.push(curr_data)
          block[curr_data.varname]
          @hint_data_stack.pop
        end
        if get_data_src
          curr_data.with_varname(new_varname) do
            put_src "#{curr_data.varname} = #{get_data_src} # #{current_data.class}"
            withdata_do[]
          end
        else
          withdata_do[]
        end
      end

      def with_dictionary(dictdataname, &block)
        put_src "# with_dictionary #{dictdataname}" if @debug_compiler
        save_dictvar = @current_dictionary_varname
        @current_dictionary_varname = dictdataname
        yield
      ensure
        @current_dictionary_varname = save_dictvar
      end

      def compile(node, hint=nil)
        init_src(hint)
        node = Node::to_node(node)
        with_data(nil) do |get_data_src|
          with_dictionary(get_data_src) do
            node.compile(self)
          end
        end
        flush_text
        @src
      end

      def get_result
        ret = [ "include Amrita", "extend Amrita::HtmlCompiler::RuntimeRoutines" ]
        ret += const_def_src
        ret << ""
        ret << "def self::expand(#{@dynamic_formatter_var_name}, #{@model_var_name}, #{@context_var_name})"
        ret += @src
        ret << "end"
      end

      def put_text(text)
        @static_formatter.with_stream(@buffer) do
          @static_formatter.format_text(text)
        end
      end

      def <<(text)
        @buffer << text.to_s
      end

      def flush_text
        if @buffer and @buffer.size > 0
          c = new_constant(@buffer.inspect)
          @src << "#{indent_space}#{@dynamic_formatter_var_name} << #{c}" 
          @buffer = ""
        end
      end

      def indent_space
        " " * (@offset*@level)
      end

      def level_up(&block)
        @level += 1
        yield
        @level -= 1
      end

      def level_down(&block)
        @level -= 1
        yield
        @level += 1
      end

      def put_src(src)
        flush_text
        @src << indent_space + src
      end

      def _if(cond, &block)
        put_src "if #{cond}"
        level_up do
          yield
        end
        put_src "end"
      end

      def _else(&block)
        level_down do
          put_src "else"
          level_up do
            yield
          end
        end
      end

      def _each(enum, &block)
        vn = new_varname
        put_src "#{enum}.each do |#{vn}|"
        level_up do
          yield(vn)
        end
        put_src "end"
      end

      def _case(caseobj, &block)
        put_src "case #{caseobj}"
        level_up do
          yield
        end
        put_src "end"
      end

      def _when(*val, &block)
        level_down do
          put_src "when #{val.join(',')}"
          level_up do
            yield
          end
        end
      end

      def _elsecase(&block)
        level_down do
          put_src "else"
          level_up do
            yield
          end
        end
      end

      def put_static_element(e, &block)
        put_src " # put_static_element " if @debug_compiler 
        put_src " # #{current_data.class} #{@current_dictionary_varname}" if @debug_compiler
        return if compile_var_attr(e, &block)
          
        e2 = e.clone
        
        hid = e.hid
        if hid and @delete_id
          e2.delete_attr!(:id)
        end
        
        if e.no_child? and @static_formatter.can_be_single?(e)
          self << @static_formatter.format_single_tag(e)
          return
        end

        need_end_tag = true

        if hid
          _if("#{context_var_name}.do_delete_id") do
            if e2.tagname == "span" and e2.attrs.size() == 0
              need_end_tag = false
            else
              self << @static_formatter.format_start_tag(e2)
            end
            _else do
              if e.tagname == "span" and e.attrs.size() == 0
                need_end_tag = false
              else
                self << @static_formatter.format_start_tag(e)
              end
            end
          end
        else
          if e.tagname == "span" and e.attrs.size() == 0
            need_end_tag = false
          else
            self << @static_formatter.format_start_tag(e)
          end
        end

        level_up do
          if block_given?
            yield
          else
            self << @static_formatter.format(e.body, "")
          end
        end

        if need_end_tag
          self << @static_formatter.format_end_tag(e)
        end
      end

      def put_dynamic_element(element_src, &block)
        put_src " # put_dynamic_element " if @debug_compiler
        put_src "e = #{element_src}"
        if @delete_id
          _if("#{context_var_name}.do_delete_id") do 
            put_src "e = e.clone"
            put_src "e.delete_attr!(:id)"
          end
        end

        _if("e.no_child? and #{dynamic_formatter_var_name}.can_be_single?(e)") do
          put_src "#{@dynamic_formatter_var_name} << #{@dynamic_formatter_var_name}.format_single_tag(e)"
          _else do
            if block_given?
              put_src("#{@dynamic_formatter_var_name}.format_element(e) do")
              level_up do
                yield
              end
              put_src("end")
            else
              put_src("#{@dynamic_formatter_var_name}.format_element(e)")
            end
          end
        end
      end

      def do_copy(&block)
        put_src(%Q[#{@context_var_name}.do_copy do])
        level_up do
          yield
        end
        put_src(%Q[end])
      end

      def filter_nil_and_enum(data_src, &block)
        var = new_varname
        put_src "filter_nil_and_enum(#{data_src}) do |#{var}|"
        level_up do
          yield(var)
        end
        put_src("end")
      end

      def compile_id_element(e)
        with_data(e.hid) do |get_data_src|
          current_data.compile(e, self)
        end
      end

      def debug_put_backtrace
        caller.each { |stack|
          put_src "# #{stack}"
        }
      end

      def compile_var_attr(element, &block)
        return false unless @current_dictionary_varname
        return false unless @expand_attr
        return false unless element.has_expandable_attr?

        e = element

        self << "<#{e.tagname}"
        last_item = e.attrs.size - 1
        e.attrs.each_with_index do |attr, n|
          if attr.key_symbol == :id
            _if("not #{context_var_name}.do_delete_id") {
              compile_static_attr(attr, e)
            }
          else
            if attr.value
              compile_attr_with_value(attr, e)
            else
              compile_static_attr(attr, e)
            end
          end
        end
        self << ">"
        if block_given?
          yield
        else
          e.body.compile(self)
        end
        unless e.no_child? and @static_formatter.can_be_single?(e)
          self <<  @static_formatter.format_end_tag(e)
        end
        true
      end

      private
      DUMMY_ATTR_VALUE = "__AMRITA_COMPILER_ATTRVAL__"
      def compile_attr_with_value(attr, element)
        val = attr.value.to_s
        if val[0] == ?@
          dummy_attr = Attr.new(attr.key, DUMMY_ATTR_VALUE)
          dummy_attr =
            @static_formatter.format_attr_of_element(dummy_attr, element)
          pre_value, post_value = dummy_attr.split(DUMMY_ATTR_VALUE, 2)

          self << " " << pre_value
          model_expr =
            "#{@current_dictionary_varname}.amrita_get_data(:#{val[1..-1]}, nil, #{context_var_name})"
          put_src("#{dynamic_formatter_var_name} << #{model_expr}.to_s.amrita_sanitize_as_attribute")
          self << post_value
        else
          compile_static_attr(attr, element)
        end
      end

      def compile_static_attr(attr, element)
        self << " " << @static_formatter.format_attr_of_element(attr, element)
      end
    end

    # the second candidate for no-hint compiler
    class AnyData < Hint #:nodoc:
      def new_data(compiler, subdataname)
        return self, varname
      end

      def compile(element, compiler)
        save = varname
        hid = element.hid
        if hid
          compile_with_id(element, compiler, hid)
        else
          compiler.with_dictionary(varname) do
            if element.has_id_element?
              compiler.put_static_element(element) do
                element.body.compile(compiler)
              end
            else
              compiler.put_static_element(element)
            end
          end
        end
      ensure
        self.varname = save
      end

      def compile_with_id(e, c, hid=nil)
        c.filter_nil_and_enum(varname) do |vn|
          c.current_data.varname = vn
          c._case(vn) do
            c._when("true") do
              c.put_static_element(e)
            end

            c._when("String", "Numeric") do
              c.put_static_element(e) do
                c.put_src("#{c.dynamic_formatter_var_name}.format_text #{varname}.to_s ")
              end
            end

            c._when("Amrita::DictionaryData") do
              c.with_dictionary(varname) {
                if hid
                  vn = varname
                  with_varname(c.new_varname) do
                    c.put_src("#{varname} = get_data_from_dictionary(#{vn}, :#{hid})")
                    ee = e.clone
                    ee.delete_attr!(:id) if c.delete_id 
                    ee.hide_hid!
                    compile_with_id(ee, c, nil)
                  end
                else
                  if e.no_child?
                    c.put_static_element(e) do
                      compile_for_unknown(Amrita::e(:span), c)
                    end
                  else
                    # c.put_src("p 9999")
                    # c.put_src("p #{varname}")
                    # c.put_src("p #{e.to_ruby}")
                    c._if("#{varname}.kind_of?(PartsTemplate) or #{varname}.kind_of?(MergeTemplate)") do
                      c.put_src(" #{varname}.amrita_expand_and_format(#{e.to_ruby}, #{c.context_var_name}, #{c.dynamic_formatter_var_name}) ")
                      c._else do 
                        e.compile(c)
                      end
                    end
                  end
                end
              }
            end

            c._elsecase do
              compile_for_unknown(e, c)
            end
          end
        end
      end

      def compile_for_unknown(e, compiler)
        case e
        when NullNode
        else
          NoHint::Instance.compile(e, compiler)
        end
      end

      def with_varname(new_varname = self.varname, &block)
        save = varname
        self.varname = new_varname
        yield
      ensure
        self.varname = save
      end
    end
  end
end
