# Original Copyright (C) Rubikichi
# Modified by TAKEUCHI Hitoshi
# You can redistribute it and/or modify it under the terms of
# the Ruby's licence.

module TMarshal
  module_function
  def dump(obj, port = nil)
    dumped = obj.dump_text
    if port
      port.write dumped
    end
    dumped
  end
  
  def load(port)
    eval port.read.untaint
  end
  
  def restore(port)
    load(port)
  end
end


################ dump_text for Standard Libraries

class String
  alias :dump_text :dump
  def read
    self
  end
end

class Array
  def dump_text
    "[\n"+self.collect{|x| x.dump_text+",\n"}.to_s+"]"
  end
end

class Numeric
  alias :dump_text :inspect
end

class Hash
  def dump_text
    "{\n"+self.collect{|k,v| "#{k.dump_text} => #{v.dump_text},\n"}.to_s+"}"
  end
end

class TrueClass
  def dump_text
    "true"
  end
end

class FalseClass
  def dump_text
    "false"
  end
end

class NilClass
  def dump_text
    "nil"
  end
end

class Module
  alias :dump_text :inspect
end

class Range
  alias :dump_text :to_s
end

class Regexp
  alias :dump_text :inspect
end

class Symbol
  alias :dump_text :inspect
end

class Time
  def dump_text
    "Time.at(#{self.to_i})"
  end
end

if __FILE__ == $0
  class C
    def initialize(v)
      @v = v
    end
    attr :v
    def dump_text
      "#{self.class}::new(#{@v.dump_text})"
    end
    def ==(other)
      @v == other.v
    end
  end

 File::open("aaa", "w") do |f|  
  [true, false, nil, Object, :a, /x/, 1..2, 3...4, Time.now, 'ABC'].each do |x|
    f.puts TMarshal::dump(x)
  end
 end

 File::open("aaa", "r") do |f|
   f.each do |a|
     c = TMarshal::load(a.chomp!)
     puts c, c.class
   end
 end
end
