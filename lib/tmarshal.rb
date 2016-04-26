# Original Copyright (C) Rubikichi
# Modified by TAKEUCHI Hitoshi
# You can redistribute it and/or modify it under the terms of
# the Ruby's licence.

module TMarshal
  module_function
  def dump(obj, port = nil)
    dumped = dump_text(obj)
    if port
      port.write dumped
    end
    dumped
  end

  def load(port)
    case port
    when String
      eval port.untaint
    when IO, StringIO
      eval port.read.untaint
    else
      raise "Wrong type!"
    end
  end

  def restore(port)
    load(port)
  end

  def dump_text(obj)
    case obj
    when String
      obj.dump
    when Array
      "[\n"+obj.collect{|x| dump_text(x)+",\n"}.join+"]"
    when Hash
      "{\n"+obj.sort_by{|e| e[0].inspect}.collect{|k,v| "#{dump_text(k)} => #{dump_text(v)},\n"}.join+"}"
    when Numeric, Module, Regexp, Symbol, TrueClass, FalseClass, NilClass, Range
      obj.inspect
    when Time
      "Time.at(#{obj.to_i})"
    else
      raise "Wrong type!"
    end
  end
end

if __FILE__ == $0
  puts TMarshal.dump({age: 22, lang: "Ruby", man: true, day: Time.now})
end
