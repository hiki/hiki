#!/usr/bin/env ruby

require "rbconfig"
require "ftools"
include Config

DSTPATH = ENV["DESTDIR"] + CONFIG["rubylibdir"]
File.makedirs(DSTPATH)

def join(*arg)
  File.join(*arg)
end

def base(name)
  File.basename(name)
end

begin
  Dir.glob("hiki/**/*.rb").each do | name |
    File.makedirs(join(DSTPATH, File.dirname(name)))
    File.install(name, join(DSTPATH, name), 0644, true)
  end

  puts "install succeed!"

rescue
  puts "install failed!"
  puts $!
end
