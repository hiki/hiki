
require 'strscan'
require "amrita/node"
require "amrita/tag"

module Amrita

  class HtmlScanner  #:nodoc:all
    include Amrita

    def HtmlScanner.scan_text(text, &block)
      scanner = new(text)
      pos = -1
      loop do
	state, value = *(scanner.scan { text[pos+=1] })
	#puts ":#{state}:#{value.type}" 

	break unless state

	yield(state, value)
      end
    end

    def initialize(src, taginfo=DefaultHtmlTagInfo)
      @sc = StringScanner.new(src)
      @taginfo = taginfo
      @src_str = src
      @text = ""
      @tagname = ""
      @attrs = []
      @attrname = ""
      @attrvalue = ""
      @push_back_value = []
      @state = method(:state_text)
    end

    def scan
      if @push_back_value.size > 0
	return @push_back_value.pop 
      end
      loop do
	return nil if  @sc.empty?
	@pointer = @sc.pointer
	#next_text = @sc.peek(10)
	#puts "#{next_text}:#{state}:#{value}:#{@state}"
	state, value = *@state.call
	#puts "#{state}:#{value}:#{@state}"

	return [state, value] if state
      end
    end

    def push_back(state, value)
      @push_back_value.push([state, value])
    end

    def empty?
      @push_back_value.size == 0 and @sc.empty?
    end

    def generate_tag
      @tagname.downcase!
      klass = @taginfo.get_tag_info(@tagname).tag_class || Tag
      ret = klass.new(@tagname, @attrs)
      @tagname = ""
      @attrs = []
      [:tag, ret]
    end

    def state_text
      t = @sc.scan(/\A[^<]*/m)
      if t
	@state = method(:state_tagname)
	t.gsub!("&gt;", ">")
	t.gsub!("&lt;", "<")
	t.gsub!("&amp;", "&")
	t.gsub!("&quot;", '"') #"
	#t.gsub!("&nbsp;", " ")
        t.gsub!(/&#(\d+);/) { $1.to_i.chr } 
	if t.size > 0
	  [:text, t]
	else
	  nil
	end
      else
	[:text, @sc.scan(/\A.*/m)]
      end
    end

    def state_tagname
      l = @sc.skip(/\A</)
      raise "can't happen" unless l == 1
      
      @sc.skip(/\A\s+/m)
      if t = @sc.scan(/\A[\/\w]+/)
	@state = method(:state_space)
	@tagname = t
	nil
      elsif t = @sc.scan(/\A!--|%=|%|\?|!/)
	@state = method(:state_special_tag)
	@tagname = t
	nil
      elsif t = @sc.scan(/\A[^>]+/m)
	@sc.skip(/\A>/)
	@tagname = t
	@state = method(:state_text)
	generate_tag
      else
	raise "can't happen"
      end
    end

    # <と>の間のスペース
    def state_space
      @sc.skip(/\A\s*/m)
      if @sc.scan(/\A>|\/>/)
	@state = method(:state_text)
	generate_tag
      elsif t = @sc.scan(/\A[\w-]+/m)
	@attrname = t
	@state = method(:state_attrname)
	nil
      else
	raise "can't happen"	
      end
    end

    def state_attrname
      @sc.skip(/\A\s*/m)
      if t = @sc.scan(/\A[\w-]+/m)
	@attrname = t
	@state = method(:state_before_equal)
	nil
      elsif t = @sc.scan(/\A=/)
	@state = method(:state_after_equal)
	nil
      elsif t = @sc.scan(/\A>|\/>/)
	@attrs << [@attrname, nil]
	@state = method(:state_text)
	generate_tag
      else
	raise "can't happen"	
      end
    end

    def state_before_equal
      @sc.skip(/\A\s*/m)
      if t = @sc.scan(/\A=/)
	@state = method(:state_after_equal)
	nil
      elsif t = @sc.scan(/\A>|\/>/) 
	@attrs << [@attrname, nil]
	@state = method(:state_text)
	generate_tag
      elsif t = @sc.scan(/\A\w+/)
	@attrs << [@attrname, nil]
	@attrvalue = ""
	@attrname = t
	@state = method(:state_attrname)
	nil
      else
	raise "can't happen"	
      end
    end

    def state_after_equal
      @sc.skip(/\A\s*/m)
      if t = @sc.scan(/\A"/) #"
	@state = method(:state_dqvalue)
	nil
      elsif t = @sc.scan(/\A'/) #'
	@state = method(:state_sqvalue)
	nil
      elsif t = @sc.scan(/\A>|\/>/)
	@attrs << [@attrname, nil]
	@state = method(:state_text)
	generate_tag
      elsif t = @sc.scan(/\A[^\s>]+/m)
	@attrs << [@attrname, t]
	@state = method(:state_space)
	nil
      elsif t = @sc.scan(/\A[^>]*/m)
	@attrs << [@attrname, t]
	@state = method(:state_attrname)
	nil
      else
	raise "can't happen"	
      end
    end
    
    def state_sqvalue
      t = @sc.scan(/\A[^']*/m) #'
      if t
        @attrs << [@attrname, t]
	@state = method(:state_space)
	@sc.skip(/\A'/) #'
	nil
      else
	raise "can't happen"	
      end
    end

    def state_dqvalue
      t = @sc.scan(/\A[^"]*/m) #"
      if t
        @attrs << [@attrname, t]
	@state = method(:state_space)
	@sc.skip(/\A"/) #"
	nil
      else
	raise "can't happen"	
      end
    end

    def state_special_tag
      re = end_tag_size = nil
      case @tagname
      when '%=', '%'
        re = /\A[^>]*%>/m
        end_tag_size = -2
      when '!--'
        re = /\A.*?-->/m 
        end_tag_size = -3
      when '?'
        re = /\A([^>]*)\?>/m
        end_tag_size = -2
	when '!'
        re = /\A([^>]*)>/m
        end_tag_size = -1
      else
        raise "can't happen"	
      end
      t = @sc.scan_until(re)
      raise "can't happen" unless t
      text = t[0...end_tag_size]
      @state = method(:state_text)
      [:special_tag, [@tagname, text]]
    end

    def current_line
      @sc.string[@pointer, 80]    
    end

    def current_line_no
      #done = @sc.string[0, @pointer]    
      done = @src_str[0, @pointer]    
      done.count("\n")
    end
  end

  class HtmlParseError < StandardError
    attr_reader :error, :fname, :lno, :line

    def initialize(error, fname, lno, line)
      @error, @fname, @lno, @line = error, fname, lno, line
      super("error hapend in #{@fname}:#{@lno}(#{error}) \n==>#{line}")
    end
  end

  class HtmlParser
    def HtmlParser.parse_inline(text, taginfo=DefaultHtmlTagInfo, &filter_proc)
      c = caller(1)[0].split(":")
      parser = HtmlParser.new(text, c[0], c[1].to_i, taginfo, &filter_proc)
      parser.parse
    end

    def HtmlParser.parse_text(text, fname=nil, lno=0, taginfo=DefaultHtmlTagInfo, &filter_proc)
      parser = HtmlParser.new(text, fname, lno, taginfo, &filter_proc)
      parser.parse
    end

    def HtmlParser.parse_io(io, fname=nil, lno=0, taginfo=DefaultHtmlTagInfo, &filter_proc)
      parser = HtmlParser.new(io.read, fname, lno, taginfo, &filter_proc)
      parser.parse
    end

    def HtmlParser.parse_file(fname, taginfo=DefaultHtmlTagInfo, &filter_proc)
      File.open(fname) do |f|
	HtmlParser.parse_io(f, fname, 0, taginfo, &filter_proc)
      end
    end

    def initialize(source, fname=nil, lno=0, taginfo=DefaultHtmlTagInfo, &filter_proc)  #:nodoc:
      @scanner = HtmlScanner.new(source, taginfo)
      @fname = fname
      @lno = lno
      @level = 1
      if block_given?
        @filter_proc = filter_proc
      else
        @filter_proc = proc {|e| e}
      end
    end

    def parse(parent_tag=HtmlScanner::Tag.new)  #:nodoc:
      ret = parse1(parent_tag)
      unless @scanner.empty?
	state, value = *@scanner.scan 
	raise "unmatched tag #{value}"
      end
      ret
    rescue
      #raise HtmlParseError.new($!, @fname,  @lno + @scanner.current_line_no, @scanner.current_line)
      raise HtmlParseError.new($!, @fname,   @scanner.current_line_no, @scanner.current_line)
    end

    def parse1(parent_tag=HtmlScanner::Tag.new)  #:nodoc:
      @level += 1
      state, value = *@scanner.scan 
      node = Amrita::Null
      begin
	while state
	  case state
	  when :tag
	    if value.empty_tag? or value.start_tag?
	      if parent_tag.accept_child(value.name)
		node += @filter_proc.call(value.generate_element(self))
	      else
		raise "<#{value.name}> can't be in <#{parent_tag.name}>" unless parent_tag.can_omit_endtag?
		@scanner.push_back(state, value)
		break
	      end
	    else
	      if parent_tag.name == value.name[1..-1]
		break
	      else
		raise "<#{value.name}> can't be in <#{parent_tag.name}>" unless parent_tag.can_omit_endtag?
		@scanner.push_back(state, value)
		break
	      end
	    end
	  when :text
	    node += TextElement.new(value)
	  when :special_tag
	    se = SpecialElement.new(value[0], value[1], @fname, @scanner.current_line_no)
	    node += se
	  when nil
	    break
	  else
	    raise "can't happen(unknown scanner_token #{state}"
	  end
	  state, value = *@scanner.scan 
	end
      end
      @level -= 1
      return node
    end
  end
end

