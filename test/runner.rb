#!/usr/bin/env ruby
require 'test/unit'

rootdir = "#{File::dirname($0)}/.."
$:.unshift( rootdir, "#{rootdir}/hiki" )

exit Test::Unit::AutoRunner.run(true, File.dirname($0))
