require 'singleton'
require 'amrita/template'

module Amrita
  class AmsTemplate < TemplateFile
    RScript1 = %r[<AmritaScript type="([^"]*)">\s*<!--\s*(.*?)\s*//-->\s*</AmritaScript>\s*]mi
    RScript2 = %r"<AmritaScript>\s*<!--\s*(.*?)\s*//-->\s*</AmritaScript>\s*"mi
    @@cache_dir = ENV["AmritaCacheDir"].untaint  # be careful whether this directory is safe
    @@template_cache = {} 

    def load_ams_template
      File.open(@path) do |f|
        @template_text  = f.read
      end
      typ, script = nil, nil
      case @template_text 
      when RScript1
        typ, script = $1, $2
        @template_text.gsub!( RScript1, "") 
      when RScript2
        typ, script = "eval", $1
        @template_text.gsub!( RScript2, "") 
      else
        # do nothing
      end

      @ams_type = typ
      case @ams_type
      when "eval"
        script = script.untaint
        @data = eval(script, TOPLEVEL_BINDING)
      when "module"
        script = script.untaint
        cls = Class.new
        cls.module_eval script
        obj = cls.new
        obj.extend ExpandByMember
        @data = obj
      when "yaml"
        require "yaml"
        @data = YAML::load script
      when nil
        @data = Hash.new(true)
      else
        raise "unknown script type #{typ}"
      end
    end

    def load_template

      @template = get_parser_class.parse_text(@template_text) do |e|
        if @parser_filter
          @parser_filter.call(e)
        else
          e
        end
      end
    end

    def setup_context
      context = super
      if @ams_type == "yaml"
        context.hash_key_is_string = true 
        context.expand_attr = true
      end
      context
    end

    def expand(stream)
      load_ams_template 
      if need_update?
        setup_template 
      end
      context = setup_context
      formatter = setup_formatter(stream)
      do_expand(@data, context, formatter)
    end


    def cache_path
      if @@cache_dir
        @@cache_dir + "/" + File::basename(@path) + ".amrita"
      else
        nil
      end
    end

    def cache_valid?
      if @@cache_dir and FileTest::readable?(cache_path) 
        File::stat(@path).mtime <= File::stat(cache_path).mtime
      else
        false
      end
    end

    def AmsTemplate::[](path)
      ret = @@template_cache[path]
      unless ret
        @@template_cache[path] = ret = AmsTemplate.new(path)
      end
      ret
    end
  end
end
