# $Id: pluginutil.rb,v 1.1 2004-04-06 16:01:14 fdiary Exp $
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

require 'cgi'

module Hiki
  module Util
    module_function
    def apply_plugin(str, plugin)
      return str unless $use_plugin
      method, *args = methodwords(str)
      begin
        if plugin.respond_to?(method) && !Object.method_defined?(method)
          if args
            plugin.send(method, *args)
          else
            plugin.send(method)
          end
        else
          raise PluginException, 'not plugin method'
        end
      rescue
        raise PluginException, plugin_error('inline plugin', $!)
      end
    end

    def argwords(args)
      args= String.new(args) rescue 
      raise(ArgumentError, "Argument must be a string")
      
      args.lstrip!
      words = []
      is_ary = false
      until args.empty?
	field = ''
	loop do
	  if args.sub!(/\A\[/, '') then
	    child_words, args = argwords(args)
	    words << child_words
	    break
	  elsif args.sub!(/\A\]/, '') then
	    break
	  elsif args.sub!(/\A"(([^"\\]|\\.)*)"/, '') then
	    snippet = $1.gsub(/\\(.)/, '\1')
	  elsif args =~ /\A"/ then
	    raise ArgumentError, "Unmatched double quote: #{args}"
	  elsif args.sub!(/\A'([^']*)'/, '') then
	    snippet = $1
	  elsif args =~ /\A'/ then
	    raise ArgumentError, "Unmatched single quote: #{args}"
	  elsif args.sub!(/\A(\(|\)|,)/, '') then
	    snippet = nil
	    break
	  elsif args.sub!(/\A\\(.)/, '') then
	    snippet = $1
	  elsif args.sub!(/\A([^\s\\'"\(\),\]]+)/, '') then
	    snippet = $1
	  else
	    args.lstrip!
	    break
	  end
	  field.concat(snippet) if snippet
	end
	if /^[-+]?\d+(\.\d+)?$/ =~ field
	  words.push($1 ? field.to_f : field.to_i)
	elsif field.size > 0
	  field = CGI.escapeHTML(field)
	  words.push(field)
	end
      end
      [words, args]
    end

    def methodwords(line)
      line = String.new(line) rescue 
      raise(ArgumentError, "Argument must be a string")
      
      line.lstrip!
      words = []
      meth = ''
      while ! line.empty?
	if line.sub!(/\A([^\s\\'"\(\)]+)/, '') then
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
end
