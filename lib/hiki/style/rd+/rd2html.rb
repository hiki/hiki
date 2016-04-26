# rd2html.rb for Hiki/RD+
#
# Copyright (C) 2003,2004 Masao Mutoh <mutoh@highway.ne.jp>
#
# You can redistribute it and/or modify it under the terms of
# the Ruby's licence.
#
# The original rd2html-lib.rb in rdtool-0.6.11:
# Copyright (C) 2002 Tosh
#
# You can redistribute it and/or modify it under the terms of
# the Ruby's licence.

require "cgi"
require "rd/rd2html-lib"
require "hiki/style/rd+/anchorlist"
require "hiki/pluginutil"
require "hiki/util"

module Hiki
  class RD2HTMLVisitor < RD::RD2HTMLVisitor
    include Hiki::Util

    attr_reader :references, :toc
    EVAL_PLUGIN_RE = /\{\{(.*?)\}\}/m
    LAST_WORD_RE = /^[A-Z0-9_]*$/
    CLASS_RE = /\#|::|\./
    CHR_ENTITY_RE = "&lt;|&gt;|&amp;|&quot;"
    CONSTANT_RE = /([a-zA-Z0-9_\+!\?\=\|\[\]]|#{CHR_ENTITY_RE})+/
    ESC_WORD = "_h_i-k-i_"
    ESC_WORD_RE = /#{ESC_WORD}/

    def initialize(plugin, db, conf)
      super()
      @title = "Untitled"
      @plugin = plugin
      @db = db
      @conf = conf
      @references = []
      @regex = nil
      @toc = []

      if text = @db.load("ModuleNames")
        @modulenames = text.split(/\s/).join("|")
        @esc_modulenames = /(#{text.split(/\s/).join(ESC_WORD + "|") + ESC_WORD})/
        @regex_modulenames = /#{@modulenames}/
        @regex = /(#{@modulenames})[\#\.\:](#{CHR_ENTITY_RE}|[a-zA-Z0-9_\#\.\:\=\[])*(#{CHR_ENTITY_RE}|[a-zA-Z0-9_!\+\?\=&\|\]])/
      end

      # InterWikiName
      @anchorlist = AnchorList.new(@db.load(@conf.interwiki_name), plugin)
    end

    def get_anchor(element)
      escape(element.label)
    end

    def div_class_method(s)
      if sep = s.scan(CLASS_RE)
        # Gtk::Hoge#fuga, Gtk::Hoge.fuga, Gtk::Hoge::Foo
        # If Gtk::Hoge. << period for document, unscan it.
        if constant = s.scan(CONSTANT_RE)
          constant = unescape_html(constant)
          child = div_class_method(s)
          if child
            [sep, constant] << child
          else
            [sep, constant]
          end
        else
          [sep]
        end
      else
        nil
      end
    end

    def special_parse(content)
      return content if content.nil? or content == ""
      # Eval Plugin
      content = content.gsub(EVAL_PLUGIN_RE) do |match|
        method = unescape_html($1)
        ret = ""
        begin
          ret = Hiki::Util.apply_plugin(method, @plugin, @conf)
          ret.gsub!(@regex_modulenames, "\\&#{ESC_WORD}") if @regex_modulenames
        rescue Exception
          err = "Plugin Error: #{$!}" # <pre>#{match}</pre>"
          if @conf.plugin_debug
            err += "</p><p>Back trace<pre>"
            $!.backtrace.each do |v|
              err += v + "\n"
              break if v =~ /special_parse/
            end
            err += "</pre>"
          end
          ret = err
        end
        ret
      end

      # Special Parse
      if @regex
        content = content.gsub(@regex) do |match|
          s =  StringScanner.new(match)
          module_name = s.scan(@regex_modulenames)
          separator = ""
          lastword = ""
          name = ""
          option = nil
          divary = div_class_method(s)

          if divary
            divary.flatten!
            lastword = divary.pop
            separator = divary.pop

            if divary.size == 0
              if separator == "::"
                if lastword =~ LAST_WORD_RE
                  # Constants
                  target = escape(module_name)
                  name = module_name + separator + lastword
                  option = lastword
                else
                  # Class
                  module_name += separator + lastword
                  target = escape(module_name)
                  name = module_name
                end
              else
                # Module method
                target = escape(module_name)
                name = module_name + separator + lastword
                option = module_name + escape(separator + lastword)
              end
            elsif divary.size > 1
              module_name += divary.join
              target = escape(module_name)
              name = module_name + separator + lastword
              if separator == "."
                option = "#{target}.#{escape(lastword)}"
              else
                option = escape(lastword)
              end
            end
            # Create result
            if @db.exist?(module_name)
              @references << module_name
              if option
                ret = @plugin.hiki_anchor(target + "#" + option, name)
              else
                ret = @plugin.hiki_anchor(target, name)
              end
            else
              ret = %Q[#{name}<a href=\"#{@conf.cgi_name}?c=edit&p=#{target}\">?</a>]
            end
            ret
          else
            match
          end
        end
        content = content.gsub(@esc_modulenames) do |match|
          match.gsub(ESC_WORD_RE, "")
        end
      end
      content
    end

    def apply_to_DocumentElement(element, content)
      html_body(content) + "\n"
    end

    def a_name_href(anchor, label)
      if label.is_a? String
        label.gsub!(ESC_WORD_RE, "")
        %Q[<a name="#{anchor}" href="##{anchor}" title="#{h(unescape(anchor))}">#{label}</a>]
      else
        label[0].gsub!(ESC_WORD_RE, "")
        %Q[<a name="#{anchor}" href="##{anchor}" title="#{h(unescape(anchor))}">#{label[0]}</a>]
      end
    end

    def apply_to_Headline(element, title)
      title = special_parse(title.join)
      anchor = get_anchor(element)
      label = hyphen_escape(element.label)
      @toc.push({"level" => element.level, "index" => anchor, "title" => title})
      depth = element.level
      depth += @conf.options["rd.header_depth"] - 1 if @conf.options["rd.header_depth"]
      %Q[<h#{depth}>#{a_name_href(anchor, title)}] +
      %Q[</h#{depth}><!-- RDLabel: "#{label}" -->]
    end

    def apply_to_TextBlock(element, content)
      content = content.join("")
      content = special_parse(content)
      if (is_this_textblock_only_one_block_of_parent_listitem?(element) or
          is_this_textblock_only_one_block_other_than_sublists_in_parent_listitem?(element))
        content.chomp
      else
        %Q[<p>#{content.chomp}</p>]
      end
    end

    def apply_to_DescListItem(element, term, description)
      anchor = get_anchor(element.term)
      label = hyphen_escape(element.label)
      if description.empty?
        %Q[<dt>#{a_name_href(anchor, term)}</dt><!-- RDLabel: "#{label}" -->]
      else
        %Q[<dt>#{a_name_href(anchor, term)}</dt><!-- RDLabel: "#{label}" -->\n] +
        %Q[<dd>\n#{description.join("\n").chomp}\n</dd>]
      end
    end

    def apply_to_MethodListItem(element, term, description)
      term = parse_method(term)  # maybe: term -> element.term
      anchor = get_anchor(element.term)
      label = hyphen_escape(element.label)
      if description.empty?
        %Q[<dt>#{a_name_href(anchor, "<code>" + term + "</code>")}</dt><!-- RDLabel: "#{label}" -->]
      else
        %Q[<dt>#{a_name_href(anchor, "<code>" + term + "</code>")}</dt><!-- RDLabel: "#{label}" -->] +
        %Q[<dd>\n#{description.join("\n")}</dd>]
      end
    end

    def apply_to_Reference_with_URL(element, content)
      url = element.label.url
      if /\.(jpg|jpeg|png|gif)\z/ =~ url
        %Q[<img src="#{meta_char_escape(url)}" title="#{content.join("")}" alt="#{content.join("")}" />]
      else
        %Q[<a href="#{meta_char_escape(url)}" class="external">#{content.join("")}</a>]
      end
    end

    def apply_to_Reference(element, content)
      content
    end

    def apply_to_RefToElement(element, content)
      content = content.join("")

      content.gsub!(@regex_modulenames, "\\&#{ESC_WORD}") if @regex_modulenames
      label = element.to_label
      key, *option = label.split(/\#/)

      if @db.infodb_exist? and @db.info_exist?(key)
        escaped = escape(key)
        if @regex_modulenames
          escaped.gsub!(@regex_modulenames, "\\&#{ESC_WORD}")
          escaped += '#' + escape(option.join.gsub(@regex_modulenames, "\\&#{ESC_WORD}")) if option and option.size > 0
        end
        @references << key
        @plugin.hiki_anchor(escaped, content)
      else
        key, option, name = @anchorlist.separate(label)
        if @anchorlist.has_key?(key)
          name = content if content
          @anchorlist.create_anchor(key, option, name)
        else
          if @regex_modulenames and @regex_modulenames =~ label
            label.gsub!(@regex_modulenames, "\\&#{ESC_WORD}")
          end
          escaped = escape(label)
          content + %Q[<a href="#{@conf.cgi_name}?c=edit;p=#{escaped}">?</a>]
        end
      end
    end

    def apply_to_Verbatim(element)
      begin
        require "rt/rt2html-lib"
        content = element.content
        if /\A#\s*RT\s*/ =~ content[0]
          content.shift
          rt_visitor = ::RT::RT2HTMLVisitor.new
          return rt_visitor.visit(::RT::RTParser.parse(content.join))
        end
      rescue LoadError
        $stderr.puts "RTtool cannot be load"
      end
      super(element)
    end
  end
end

