#!/usr/bin/env ruby
gem 'test-unit'
require 'test/unit'
require 'test/unit/notify'

rootdir = Pathname(__FILE__).dirname.parent.expand_path
$:.unshift(rootdir, "#{rootdir}/hiki")

exit Test::Unit::AutoRunner.run(true, File.dirname($0))
