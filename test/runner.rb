#!/usr/bin/env ruby
require 'bundler/setup'
gem 'test-unit'
require 'test/unit'
require 'test/unit/notify'
require 'test/unit/rr'

rootdir = Pathname(__FILE__).dirname.parent.expand_path
$LOAD_PATH.unshift(rootdir, "#{rootdir}/hiki")
$LOAD_PATH.unshift(rootdir, "#{rootdir}/test")

require "test_helper"
require "rack"

exit Test::Unit::AutoRunner.run(true, File.dirname($0))
