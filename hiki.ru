#!/usr/bin/env rackup
# -*- ruby -*-
require 'hiki/app'

use Rack::Lint
use Rack::ShowExceptions
use Rack::Reloader
#use Rack::Session::Cookie
#use Rack::ShowStatus
use Rack::CommonLogger
use Rack::Static, :urls => ['/theme'], :root => '.'

run Hiki::App.new
