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
      raise 'Wrong type!'
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
      "[\n"+obj.collect{|x| dump_text(x)+",\n"}.to_s+"]"
    when Numeric, Module, Regexp, Symbol
      obj.inspect
    when Hash
      "{\n"+obj.sort{|a,b| a[0].inspect<=>b[0].inspect}.collect{|k,v| "#{dump_text(k)} => #{dump_text(v)},\n"}.to_s+"}"
    when TrueClass
      'true'
    when FalseClass
      'false'
    when NilClass
      'nil'
    when Range
      obj.to_s
    when Time
      "Time.at(#{obj.to_i})"
    else
      raise 'Wrong type!'
    end
  end
end

if __FILE__ == $0
  File::open("aaa", "w") do |f|
    x = [true, false, nil, Object, :a, /x/, 1..2, 3...4, Time.now, 'ABC', {'a'=>1, 'b'=>2, 'c'=>3}]
    f.puts TMarshal::dump(x)
  end

  File::open("aaa", "r") do |f|
    c = TMarshal::load(f.read)
    c.each do |i|
      puts i, i.class
    end
  end
end
