#!/usr/bin/env rackup
# -*- ruby -*-
require 'hiki/farm'
require 'hiki/app'
require 'hiki/attachment'

use Rack::Lint
use Rack::ShowExceptions
use Rack::Reloader
#use Rack::Session::Cookie
#use Rack::ShowStatus
use Rack::CommonLogger
use Rack::Static, :urls => ['/theme'], :root => '.'

map '/' do
  run Hiki::Farm::Dispatcher.new
end
