
require 'rubygems'
require 'rack'

require 'hiki/config'

$LOAD_PATH.unshift 'hiki'

module Hiki
  class App
    def call(env)
      request = Rack::Request.new(env)
      # TODO use Rack::Request#env or other methods instead of ENV
      conf = Hiki::Config.new
      db = conf.database
      response = nil
      db.open_db do
        command = Hiki::Command.new(request, db, conf)
        response = command.dispatch
      end
      # [body, status, headers]
      # Rack::Response.new(*response){|r|
      # }.finish
      response.header.delete('status')
      response.finish
    end
  end
end
