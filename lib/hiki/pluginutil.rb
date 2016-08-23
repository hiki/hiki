#
# apply_plugin(str):
#  Eval the string as a plugin.
#
# methodwords(str):
#  Separte a string to a method and arguments for plugins.
#
# Copyright (C) 2004 Masao Mutoh <mutoh@highway.ne.jp>
#
# Based on shellwords.rb(in ruby standard library).

require "cgi" unless Object.const_defined?(:Rack)
require "erb"

module Hiki
  module Util
    DIGIT_RE = /^[-+]?\d+(\.\d+)?$/
    STRING_RE = /\A"(.*)"\z/m
    NIL_RE = /^\s*nil\s*$/
    LSTRIP_RE = /\A\s+/

    module_function
    def apply_plugin(str, plugin, conf)
      return str unless conf.use_plugin
      set_conf(conf)
      method, *args = methodwords(str)
      begin
        method.untaint
        if plugin.respond_to?(method) && !Object.method_defined?(method)
          if args
            plugin.send(method, *args)
          else
            plugin.send(method)
          end
        else
          raise PluginException, "not plugin method"
        end
      rescue Exception
        raise PluginException, plugin_error("inline plugin", $!)
      end
    end

    def convert_value(field, escape = false)
      if DIGIT_RE =~ field
        $1 ? field.to_f : field.to_i
      elsif STRING_RE =~ field
        $1
      elsif NIL_RE =~ field
        nil
      elsif field.size > 0
        field = ERB::Util.h(field) if escape
        field
      else
        :no_data
      end
    end

    ARG_REG_A = /\A\[/
    ARG_REG_B = /\A\]/
    ARG_REG_C = /\A"(([^"\\]|\\.)*)"/
    ARG_REG_D = /\\(.)/
    ARG_REG_E = /\A"/
    ARG_REG_F = /\A'([^']*)'/
    ARG_REG_G = /\A'/
    ARG_REG_H = /\A(\(|\)|,)/
    ARG_REG_I = /\A\\(.)/
    ARG_REG_J = /\A([^\s\\'"\(\),\]]+)/

    def argwords(args, escape = false)
      args= String.new(args) rescue
      raise(ArgumentError, "Argument must be a string")

      args.sub!(LSTRIP_RE, "")
      words = []
      is_ary = false
      until args.empty?
        field = ""
        loop do
          if args.sub!(ARG_REG_A, "") then
            child_words, args = argwords(args)
            words << child_words
          elsif args.sub!(ARG_REG_B, "") then
            val = convert_value(field, escape)
            words.push(val) unless val == :no_data
            return [words, args]
          elsif args.sub!(ARG_REG_C, "") then
            snippet = %Q|"#{$1.gsub(ARG_REG_D, '\1').gsub(/"/, '&quot;')}"|
          elsif args =~ ARG_REG_E then
            raise ArgumentError, "Unmatched double quote: #{args}"
          elsif args.sub!(ARG_REG_F, "") then
            snippet = %Q|"#{$1.gsub(/"/, '&quot;')}"|
          elsif args =~ ARG_REG_G then
            raise ArgumentError, "Unmatched single quote: #{args}"
          elsif args.sub!(ARG_REG_H, "") then
            snippet = nil
            break
          elsif args.sub!(ARG_REG_I, "") then
            snippet = $1
          elsif args.sub!(ARG_REG_J, "") then
            snippet = $1
          else
            args.sub!(LSTRIP_RE, "")
            break
          end
          field.concat(snippet) if snippet
        end
        val = convert_value(field, escape)
        words.push(val) unless val == :no_data
      end
      [words, args]
    end

    METHOD_REG_A = /\A([^\s\\'"\(\)]+)/

    def methodwords(line)
      line = String.new(line) rescue
      raise(ArgumentError, "Argument must be a string")

      line.sub!(LSTRIP_RE, "")
      words = []
      meth = ""
      while ! line.empty?
        if line.sub!(METHOD_REG_A, "") then
          meth.concat($1)
          words.push(meth)
        else
          child_words, = argwords(line)
          words += child_words
          break
        end
      end
      words
    end
  end
end

if __FILE__ == $0
  p Hiki::Util.methodwords("foo")
  p Hiki::Util.methodwords(%Q[foo "bar", "a
iueo|
kaki"])
  p Hiki::Util.methodwords(%Q[foo('ba"r', "a'iueo" )])
  p Hiki::Util.methodwords(%Q[foo File, ["h]oge", "f[uga"], "bar", [1, 2.0, 0.4]])
  p Hiki::Util.methodwords(%Q[foo [[0,1],[2,3]]])
  p Hiki::Util.methodwords(%Q[foo nil, nil, "hoge"])
end
